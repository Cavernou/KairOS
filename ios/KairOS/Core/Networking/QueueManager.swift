import Foundation
import SQLite3

actor QueueManager {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        self.dbPath = (documentsPath as NSString).appendingPathComponent("queue.db")
        setupDatabase()
    }
    
    private func setupDatabase() {
        sqlite3_open(dbPath, &db)
        
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS message_queue (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            sender_kair TEXT NOT NULL,
            receiver_kair TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            encrypted_payload BLOB NOT NULL,
            node_route TEXT,
            has_attachments INTEGER DEFAULT 0,
            retry_count INTEGER DEFAULT 0,
            next_retry INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            expires_at INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','sent','delivered','failed'))
        );
        """
        
        var createTableStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableSQL, -1, &createTableStmt, nil) == SQLITE_OK {
            sqlite3_step(createTableStmt)
            sqlite3_finalize(createTableStmt)
        }
    }
    
    func enqueue(_ packet: MessagePacket) {
        let now = Date().timeIntervalSince1970
        let expiresAt = now + (7 * 24 * 60 * 60) // 7 days TTL
        let nextRetry = now // Immediate retry first
        
        let insertSQL = """
        INSERT OR REPLACE INTO message_queue 
        (id, type, sender_kair, receiver_kair, timestamp, encrypted_payload, node_route, has_attachments, 
         retry_count, next_retry, created_at, expires_at, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, 'queued');
        """
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (packet.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (packet.type as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (packet.senderKair as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (packet.receiverKair as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 5, Int64(packet.timestamp))
            sqlite3_bind_blob(stmt, 6, [UInt8](packet.encryptedPayload), Int32(packet.encryptedPayload.count), nil)
            let route = packet.nodeRoute.joined(separator: ",")
            sqlite3_bind_text(stmt, 7, (route as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 8, Int64(packet.hasAttachments ? 1 : 0))
            sqlite3_bind_int64(stmt, 9, Int64(nextRetry))
            sqlite3_bind_int64(stmt, 10, Int64(now))
            sqlite3_bind_int64(stmt, 11, Int64(expiresAt))
            
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }
    
    func drain() -> [MessagePacket] {
        let now = Date().timeIntervalSince1970
        let querySQL = """
        SELECT id, type, sender_kair, receiver_kair, timestamp, encrypted_payload, node_route, has_attachments
        FROM message_queue
        WHERE status = 'queued' AND next_retry <= ?
        ORDER BY created_at ASC;
        """
        
        var stmt: OpaquePointer?
        var packets: [MessagePacket] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, Int64(now))
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(stmt, 0))
                let type = String(cString: sqlite3_column_text(stmt, 1))
                let senderKair = String(cString: sqlite3_column_text(stmt, 2))
                let receiverKair = String(cString: sqlite3_column_text(stmt, 3))
                let timestamp = sqlite3_column_int64(stmt, 4)
                let encryptedPayload = Data(bytes: sqlite3_column_blob(stmt, 5), count: Int(sqlite3_column_bytes(stmt, 5)))
                let routeStr = String(cString: sqlite3_column_text(stmt, 6))
                let hasAttachments = sqlite3_column_int(stmt, 7) != 0
                
                let packet = MessagePacket(
                    id: id,
                    type: type,
                    senderKair: senderKair,
                    receiverKair: receiverKair,
                    timestamp: timestamp,
                    encryptedPayload: encryptedPayload,
                    nodeRoute: routeStr.isEmpty ? [] : routeStr.components(separatedBy: ","),
                    hasAttachments: hasAttachments
                )
                packets.append(packet)
            }
            
            sqlite3_finalize(stmt)
        }
        
        // Mark as sent (will be updated by actual send result)
        for packet in packets {
            markSent(id: packet.id)
        }
        
        return packets
    }
    
    func markSent(id: String) {
        let updateSQL = "UPDATE message_queue SET status = 'sent' WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, updateSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }
    
    func markDelivered(id: String) {
        let updateSQL = "UPDATE message_queue SET status = 'delivered' WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, updateSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }
    
    func markFailed(id: String, retryCount: Int) {
        if retryCount >= 100 {
            // After 100 retries, mark as failed
            let updateSQL = "UPDATE message_queue SET status = 'failed' WHERE id = ?"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, updateSQL, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
                sqlite3_finalize(stmt)
            }
        } else {
            // Update retry count and next retry time with exponential backoff
            let nextRetry = calculateNextRetry(retryCount: retryCount)
            let updateSQL = """
            UPDATE message_queue 
            SET retry_count = ?, next_retry = ?
            WHERE id = ?;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, updateSQL, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(retryCount))
                sqlite3_bind_int64(stmt, 2, Int64(nextRetry))
                sqlite3_bind_text(stmt, 3, (id as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
                sqlite3_finalize(stmt)
            }
        }
    }
    
    private func calculateNextRetry(retryCount: Int) -> TimeInterval {
        // Exponential backoff: immediate, 1m, 5m, 15m, 1h, 4h, 12h, 24h
        let schedule: [TimeInterval] = [0, 60, 300, 900, 3600, 14400, 43200, 86400]
        let index = min(retryCount, schedule.count - 1)
        return Date().timeIntervalSince1970 + schedule[index]
    }
    
    func cleanupExpired() {
        let now = Date().timeIntervalSince1970
        let deleteSQL = "DELETE FROM message_queue WHERE expires_at < ? AND status = 'failed';"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, Int64(now))
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }
    
    func getQueueStatus() -> (queued: Int, sent: Int, delivered: Int, failed: Int) {
        let querySQL = """
        SELECT status, COUNT(*) FROM message_queue GROUP BY status;
        """
        
        var stmt: OpaquePointer?
        var queued = 0, sent = 0, delivered = 0, failed = 0
        
        if sqlite3_prepare_v2(db, querySQL, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let status = String(cString: sqlite3_column_text(stmt, 0))
                let count = Int(sqlite3_column_int(stmt, 1))
                
                switch status {
                case "queued": queued = count
                case "sent": sent = count
                case "delivered": delivered = count
                case "failed": failed = count
                default: break
                }
            }
            sqlite3_finalize(stmt)
        }
        
        return (queued, sent, delivered, failed)
    }
}
