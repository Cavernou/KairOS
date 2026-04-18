let timerInterval = null;
let cooldownInterval = null;
let isAuthenticated = false;
let lastRefreshTime = 0;
const COOLDOWN_PERIOD = 30000; // 30 seconds cooldown

// Temp sounds storage - user can add custom sounds later
const tempSounds = {};

// Ambient sound player
let ambientPlayer = null;
let ambientEnabled = true;
let ambientVolume = 0.3;

// Sound playback
function playSound(soundName, volume = 1.0) {
    console.log('Attempting to play sound:', soundName);
    // Try both mp3 and wav extensions
    const audio = new Audio(`/sounds/${soundName}.mp3`);
    audio.volume = volume;
    audio.play().catch(err => {
        console.log('MP3 play failed, trying WAV:', err);
        const wavAudio = new Audio(`/sounds/${soundName}.wav`);
        wavAudio.volume = volume;
        wavAudio.play().catch(err2 => console.log('WAV play also failed:', err2));
    });
}

// Play subtle click sound
function playSubtleClick() {
    const clickSounds = ['command_line_click#1', 'command_line_click#2', 'command_line_click#3', 'command_line_click#4', 'command_line_click#5'];
    const randomSound = clickSounds[Math.floor(Math.random() * clickSounds.length)];
    playSound(randomSound, 0.2); // 20% volume for very subtle clicks
}

// Play click sound
function playClick() {
    const clickSounds = ['command_line_click#1', 'command_line_click#2', 'command_line_click#3', 'command_line_click#4', 'command_line_click#5'];
    const randomIndex = Math.floor(Math.random() * clickSounds.length);
    playSound(clickSounds[randomIndex], 0.3); // 30% volume for softer button clicks
}

// Register a temp sound (user can add these later)
function registerTempSound(name, url) {
    tempSounds[name] = url;
    console.log(`Registered temp sound: ${name}`);
}

// Play a temp sound
function playTempSound(name) {
    if (tempSounds[name]) {
        const audio = new Audio(tempSounds[name]);
        audio.volume = 0.5; // Temp sounds at half volume
        audio.play();
    }
}

// Play ambient sound
function playAmbient() {
    if (!ambientEnabled) return;
    
    if (!ambientPlayer) {
        ambientPlayer = new Audio('/sounds/ambient_hum.mp3');
        ambientPlayer.loop = true;
        ambientPlayer.volume = ambientVolume;
    }
    
    ambientPlayer.play().catch(e => {
        console.log('Ambient sound not available:', e);
    });
}

// Stop ambient sound
function stopAmbient() {
    if (ambientPlayer) {
        ambientPlayer.pause();
    }
}

// Set ambient volume
function setAmbientVolume(volume) {
    ambientVolume = Math.max(0, Math.min(1, volume));
    if (ambientPlayer) {
        ambientPlayer.volume = ambientVolume;
    }
}

// Login function
function login() {
    playClick();
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorElement = document.getElementById('login-error');
    
    if (username === 'ADMIN' && password === 'Cavejoncen257585!') {
        isAuthenticated = true;
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('dashboard').style.display = 'block';
        errorElement.textContent = '';
        
        // Play access granted sound
        playSound('AccessGranted');
        
        // Start ambient sound
        playAmbient();
        
        // Initialize dashboard
        initializeDashboard();
    } else {
        errorElement.textContent = 'INVALID CREDENTIALS';
        playSound('WarningUI');
    }
}

// Logout function
function logout() {
    playClick();
    isAuthenticated = false;
    document.getElementById('login-screen').style.display = 'flex';
    document.getElementById('dashboard').style.display = 'none';
    document.getElementById('username').value = '';
    document.getElementById('password').value = '';
    
    // Stop ambient sound
    stopAmbient();
    
    // Clear timers
    if (timerInterval) {
        clearInterval(timerInterval);
    }
}

// Button click sound wrapper
function playClick() {
    // Disabled to reduce sound clutter
}

// Fetch current admin code
async function fetchAdminCode() {
    const now = Date.now();
    const timeSinceLastRefresh = now - lastRefreshTime;
    
    // Check cooldown
    if (timeSinceLastRefresh < COOLDOWN_PERIOD) {
        const remainingCooldown = COOLDOWN_PERIOD - timeSinceLastRefresh;
        const seconds = Math.ceil(remainingCooldown / 1000);
        document.getElementById('cooldown-timer').textContent = `${seconds}s`;
        playSound('WarningUI');
        return;
    }
    
    try {
        const response = await fetch('/mock/v1/admin-code');
        const data = await response.json();
        document.getElementById('admin-code').textContent = data.code;
        
        // Update last refresh time
        lastRefreshTime = now;
        
        // Play sound on refresh
        playSound('command_line_click#1');
        
        // Clear existing timer interval
        if (timerInterval) {
            clearInterval(timerInterval);
        }
        
        // Calculate expiration timer
        const expiresAt = new Date(data.expires_at);
        updateTimer(expiresAt);
        
        // Start cooldown timer
        startCooldownTimer();
    } catch (error) {
        console.error('Failed to fetch admin code:', error);
        document.getElementById('admin-code').textContent = 'ERROR';
    }
}

// Start cooldown timer
function startCooldownTimer() {
    if (cooldownInterval) {
        clearInterval(cooldownInterval);
    }
    
    cooldownInterval = setInterval(() => {
        const now = Date.now();
        const timeSinceLastRefresh = now - lastRefreshTime;
        
        if (timeSinceLastRefresh >= COOLDOWN_PERIOD) {
            document.getElementById('cooldown-timer').textContent = 'Ready';
            document.getElementById('refresh-btn').disabled = false;
        } else {
            const remainingCooldown = COOLDOWN_PERIOD - timeSinceLastRefresh;
            const seconds = Math.ceil(remainingCooldown / 1000);
            document.getElementById('cooldown-timer').textContent = `${seconds}s`;
            document.getElementById('refresh-btn').disabled = true;
        }
    }, 1000);
}

// Update expiration timer
function updateTimer(expiresAt) {
    const timerElement = document.getElementById('code-timer');
    
    timerInterval = setInterval(() => {
        const now = new Date();
        const diff = expiresAt - now;
        
        if (diff <= 0) {
            timerElement.textContent = 'EXPIRED';
            clearInterval(timerInterval);
            fetchAdminCode(); // Refresh code
            playSound('command_line_click#1'); // Play sound on refresh
            return;
        }
        
        const minutes = Math.floor(diff / 60000);
        const seconds = Math.floor((diff % 60000) / 1000);
        timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }, 1000);
}

// Refresh admin code
function refreshCode() {
    playClick();
    fetchAdminCode();
}

// Fetch device list
async function fetchDevices() {
    try {
        const response = await fetch('/mock/v1/status');
        const data = await response.json();
        
        const deviceList = document.getElementById('device-list-devices');
        
        // Display KairOS devices if available
        if (data.devices && data.devices.length > 0) {
            deviceList.innerHTML = data.devices.map(device => `
                <div class="device-item">
                    <span class="device-name">${device.kair_number || device.device_id || 'Unknown'}</span>
                    <span class="device-status">${device.activated === 'true' ? 'Active' : 'Inactive'}</span>
                    <span class="device-id">${device.device_id || ''}</span>
                </div>
            `).join('');
            
            // Populate target device dropdown
            const targetDeviceSelect = document.getElementById('target-device');
            targetDeviceSelect.innerHTML = '<option value="">Select Device</option>';
            data.devices.forEach(device => {
                const option = document.createElement('option');
                option.value = device.device_id;
                option.textContent = device.kair_number || device.device_id;
                targetDeviceSelect.appendChild(option);
            });
        } else {
            deviceList.innerHTML = '<div class="device-item"><span class="device-name">No KairOS devices registered</span></div>';
        }
        
        // Update queue stats
        if (data.queue) {
            document.getElementById('queue-pending').textContent = data.queue.pending || '0';
            document.getElementById('queue-processed').textContent = data.queue.processed || '0';
        }
        
        // Update database stats
        document.getElementById('db-devices').textContent = data.devices ? data.devices.length : '0';
        document.getElementById('db-contacts').textContent = data.contacts ? data.contacts.length : '0';
        document.getElementById('db-messages').textContent = data.messages ? data.messages.length : '0';
        document.getElementById('db-files').textContent = data.files ? data.files.length : '0';
        document.getElementById('db-codes').textContent = '1'; // Current active code
    } catch (error) {
        console.error('Failed to fetch devices:', error);
    }
}

// Upload file to target device
async function uploadFile() {
    playClick();
    const fileInput = document.getElementById('file-input');
    const targetDevice = document.getElementById('target-device').value;
    
    if (!fileInput.files.length) {
        alert('Please select a file');
        playSound('WarningUI');
        return;
    }
    
    if (!targetDevice) {
        alert('Please select a target device');
        playSound('WarningUI');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', fileInput.files[0]);
    formData.append('target_device', targetDevice);
    
    try {
        const response = await fetch('/mock/v1/files/upload', {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        if (response.ok) {
            alert(`File queued for transfer to ${targetDevice}`);
            playSound('TadaSuccess');
        } else {
            alert('File upload failed: ' + result.error);
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('File upload failed:', error);
        alert('File upload failed');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Update system stats
function updateSystemStats() {
    const startTime = Date.now();
    
    setInterval(() => {
        const now = Date.now();
        const uptime = Math.floor((now - startTime) / 1000);
        
        if (uptime < 60) {
            document.getElementById('uptime').textContent = `${uptime}s`;
        } else if (uptime < 3600) {
            const minutes = Math.floor(uptime / 60);
            document.getElementById('uptime').textContent = `${minutes}m`;
        } else {
            const hours = Math.floor(uptime / 3600);
            const minutes = Math.floor((uptime % 3600) / 60);
            document.getElementById('uptime').textContent = `${hours}h ${minutes}m`;
        }
    }, 1000);
    
    // Memory usage (simulated)
    document.getElementById('memory').textContent = '32MB';
    
    // Check Tailscale status
    checkTailscaleStatus();
}

// Check Tailscale status
async function checkTailscaleStatus() {
    try {
        const response = await fetch('/mock/v1/status');
        const data = await response.json();
        
        // Update Tailscale status based on actual response
        const tailscaleStatus = document.getElementById('tailscale-status');
        if (data.tailscale_connected) {
            tailscaleStatus.textContent = 'Connected';
            tailscaleStatus.style.color = '#00FF00';
            clearCriticalError();
        } else {
            tailscaleStatus.textContent = 'Disconnected';
            tailscaleStatus.style.color = '#FF0000';
            triggerCriticalError();
        }
    } catch (error) {
        document.getElementById('tailscale-status').textContent = 'Unknown';
        triggerCriticalError();
    }
}

// Initialize dashboard
function initializeDashboard() {
    fetchAdminCode();
    fetchDevices();
    updateSystemStats();
    checkTailscaleStatus();
    loadNews();
    loadMetrics();
    
    // Set up periodic refresh for live data
    setInterval(() => {
        fetchDevices();
        checkTailscaleStatus();
        loadMetrics();
    }, 5000); // Refresh devices, Tailscale status, and metrics every 5 seconds
}

// Setup tooltip functionality
function setupTooltips() {
    const helpIcons = document.querySelectorAll('.help-icon');
    helpIcons.forEach(icon => {
        icon.addEventListener('mouseenter', function() {
            const tooltip = this.getAttribute('data-tooltip');
            if (tooltip) {
                this.setAttribute('title', tooltip);
            }
        });
    });
}

// Show help modal
function showHelp() {
    document.getElementById('help-modal').style.display = 'block';
    makeDraggable(document.getElementById('help-modal').querySelector('.modal-content'));
}

function closeHelp() {
    document.getElementById('help-modal').style.display = 'none';
}

function closeNewsBanner() {
    document.getElementById('news-banner').style.display = 'none';
    playClick();
}

async function loadNews() {
    try {
        const response = await fetch('/mock/v1/news');
        const news = await response.json();
        
        if (news.message) {
            document.getElementById('news-message').textContent = news.message;
            document.getElementById('news-banner').style.display = 'block';
        }
    } catch (error) {
        console.error('Failed to load news:', error);
    }
}

async function loadMetrics() {
    try {
        const response = await fetch('/mock/v1/metrics');
        const metrics = await response.json();
        
        // Update CPU usage
        const cpuUsage = metrics.cpu_usage || 0;
        document.getElementById('cpu-bar').style.width = cpuUsage + '%';
        document.getElementById('cpu-value').textContent = cpuUsage.toFixed(1) + '%';
        
        // Update memory usage
        const memUsage = metrics.memory_usage || 0;
        document.getElementById('memory-bar').style.width = memUsage + '%';
        document.getElementById('memory-value').textContent = memUsage.toFixed(1) + '%';
        
        // Update goroutines
        const goroutines = metrics.goroutines || 0;
        const goroutinesPercent = Math.min(goroutines / 100 * 100, 100);
        document.getElementById('goroutines-bar').style.width = goroutinesPercent + '%';
        document.getElementById('goroutines-value').textContent = goroutines;
        
        // Update uptime
        const uptime = metrics.uptime || 0;
        const uptimeSeconds = Math.floor(uptime);
        const uptimePercent = Math.min(uptime / 3600 * 100, 100); // Scale to 1 hour
        document.getElementById('uptime-bar').style.width = uptimePercent + '%';
        document.getElementById('uptime-value').textContent = formatUptime(uptimeSeconds);
    } catch (error) {
        console.error('Failed to load metrics:', error);
    }
}

function formatUptime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

function makeDraggable(element) {
    let pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
    
    element.onmousedown = dragMouseDown;

    function dragMouseDown(e) {
        e = e || window.event;
        e.preventDefault();
        pos3 = e.clientX;
        pos4 = e.clientY;
        document.onmouseup = closeDragElement;
        document.onmousemove = elementDrag;
    }

    function elementDrag(e) {
        e = e || window.event;
        e.preventDefault();
        pos1 = pos3 - e.clientX;
        pos2 = pos4 - e.clientY;
        pos3 = e.clientX;
        pos4 = e.clientY;
        element.style.top = (element.offsetTop - pos2) + "px";
        element.style.left = (element.offsetLeft - pos1) + "px";
    }

    function closeDragElement() {
        document.onmouseup = null;
        document.onmousemove = null;
    }
}

// Switch between tabs
function switchTab(tabName) {
    // Hide all tab contents
    const tabContents = document.querySelectorAll('.tab-content');
    tabContents.forEach(tab => {
        tab.style.display = 'none';
    });

    // Remove active class from all tabs
    const tabs = document.querySelectorAll('.nav-tab');
    tabs.forEach(tab => {
        tab.classList.remove('active');
    });

    // Show selected tab content
    const selectedTab = document.getElementById(`tab-${tabName}`);
    if (selectedTab) {
        selectedTab.style.display = 'block';
    }

    // Add active class to selected tab
    const selectedTabButton = document.querySelector(`.nav-tab[onclick="switchTab('${tabName}')"]`);
    if (selectedTabButton) {
        selectedTabButton.classList.add('active');
    }

    // Load content for specific tabs
    if (tabName === 'files') {
        browseFiles('.');
    }
    
    if (tabName === 'broadcast') {
        loadBroadcasts();
    }
}

// Auto-reload mechanism
let lastVersion = null;
let autoReloadInterval = null;

function checkForUpdates() {
    fetch('/mock/v1/version')
        .then(response => response.json())
        .then(data => {
            if (lastVersion === null) {
                lastVersion = data.version;
            } else if (data.version !== lastVersion) {
                console.log('Update detected, reloading page...');
                location.reload();
            }
        })
        .catch(err => {
            console.log('Failed to check for updates:', err);
        });
}

function startAutoReload() {
    // Check for updates every 30 seconds
    autoReloadInterval = setInterval(checkForUpdates, 30000);
}

function stopAutoReload() {
    if (autoReloadInterval) {
        clearInterval(autoReloadInterval);
        autoReloadInterval = null;
    }
}

// Trigger critical error state
function triggerCriticalError() {
    document.body.classList.add('critical-error');
    playSound('DISAPPOINTING_FAILURE');
}

// Clear critical error state
function clearCriticalError() {
    document.body.classList.remove('critical-error');
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    // Add subtle click sounds to all inputs
    const inputs = document.querySelectorAll('input, select');
    inputs.forEach(input => {
        input.addEventListener('focus', () => {
            playSubtleClick();
        });
    });

    // Add click sounds to all buttons
    const buttons = document.querySelectorAll('button');
    buttons.forEach(button => {
        button.addEventListener('click', () => {
            playClick();
        });
    });

    // Don't auto-initialize - require login first
});

// Settings management
async function loadSettings() {
    try {
        const response = await fetch('/mock/v1/settings');
        const settings = await response.json();

        document.getElementById('setting-listen-addr').value = settings.listen_addr || '0.0.0.0:8080';
        document.getElementById('setting-mock-http-addr').value = settings.mock_http_listen_addr || '0.0.0.0:8081';
        document.getElementById('setting-tailnet').value = settings.tailnet || 'kairos.ts.net';
        document.getElementById('setting-tailscale-enabled').checked = settings.tailscale_enabled || false;
        document.getElementById('setting-retry-limit').value = settings.queue_retry_limit || 100;
        document.getElementById('setting-ttl').value = settings.queue_ttl_hours || 168;
        document.getElementById('setting-admin-interval').value = settings.admin_code_interval || 3600;
    } catch (error) {
        console.error('Failed to load settings:', error);
    }
}

async function saveSettings() {
    playClick();
    const settings = {
        listen_addr: document.getElementById('setting-listen-addr').value,
        mock_http_listen_addr: document.getElementById('setting-mock-http-addr').value,
        tailnet: document.getElementById('setting-tailnet').value,
        tailscale_enabled: document.getElementById('setting-tailscale-enabled').checked,
        queue_retry_limit: parseInt(document.getElementById('setting-retry-limit').value),
        queue_ttl_hours: parseInt(document.getElementById('setting-ttl').value),
        admin_code_interval: parseInt(document.getElementById('setting-admin-interval').value)
    };

    try {
        const response = await fetch('/mock/v1/settings', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(settings)
        });

        if (response.ok) {
            alert('Settings saved successfully');
            playSound('TadaSuccess');
        } else {
            alert('Failed to save settings');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to save settings:', error);
        alert('Failed to save settings');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// File browser
let currentBrowsePath = '.';
let currentFiles = [];

async function browseFiles(path) {
    try {
        const response = await fetch(`/mock/v1/files/browse?path=${encodeURIComponent(path)}`);
        const data = await response.json();
        
        currentBrowsePath = data.path;
        currentFiles = data.files;
        
        updateBreadcrumbs(data.path);
        renderFiles();
    } catch (error) {
        console.error('Failed to browse files:', error);
        document.getElementById('file-browser-list').innerHTML = '<div class="file-item"><span class="file-name">Failed to load files</span></div>';
    }
}

function updateBreadcrumbs(path) {
    const breadcrumbs = document.getElementById('file-breadcrumbs');
    const parts = path.split('/').filter(p => p !== '' && p !== '.');
    
    let html = '<span class="breadcrumb" onclick="browseFiles(\'.\')" style="cursor: pointer; color: #FFE258;">🏠 Root</span>';
    
    let currentPath = '';
    for (let i = 0; i < parts.length; i++) {
        currentPath += '/' + parts[i];
        html += ' <span class="breadcrumb-separator">›</span>';
        html += `<span class="breadcrumb" onclick="browseFiles('${currentPath}')" style="cursor: pointer; color: #FFE258;">${parts[i]}</span>`;
    }
    
    breadcrumbs.innerHTML = html;
}

function refreshFiles() {
    browseFiles(currentBrowsePath);
}

function renderFiles() {
    const fileList = document.getElementById('file-browser-list');
    const filterText = document.getElementById('file-filter').value.toLowerCase();
    const sortBy = document.getElementById('file-sort').value;
    
    // Filter files
    let filteredFiles = currentFiles.filter(file => {
        return file.name.toLowerCase().includes(filterText);
    });
    
    // Sort files
    filteredFiles.sort((a, b) => {
        if (a.is_dir && !b.is_dir) return -1;
        if (!a.is_dir && b.is_dir) return 1;
        
        if (sortBy === 'name') {
            return a.name.localeCompare(b.name);
        } else if (sortBy === 'size') {
            return b.size - a.size;
        } else if (sortBy === 'modified') {
            return b.modified - a.modified;
        }
        return 0;
    });
    
    if (filteredFiles.length > 0) {
        fileList.innerHTML = filteredFiles.map(file => {
            const filePath = currentBrowsePath === '.' ? file.name : `${currentBrowsePath}/${file.name}`;
            const clickAction = file.is_dir ? `browseFiles('${filePath}')` : `viewFile('${filePath}')`;
            return `
            <div class="file-item ${file.is_dir ? 'directory' : ''}" onclick="${clickAction}">
                <span class="file-name">${file.is_dir ? '[DIR] ' : ''}${file.name}</span>
                <span class="file-info">${formatFileSize(file.size)}</span>
            </div>
            `;
        }).join('');
    } else {
        fileList.innerHTML = '<div class="file-item"><span class="file-name">No files found</span></div>';
    }
}

function sortFiles() {
    renderFiles();
}

function filterFiles() {
    renderFiles();
}

// Broadcast management
async function sendBroadcast() {
    const message = document.getElementById('broadcast-message').value;
    const priority = document.getElementById('broadcast-priority').value;
    const expiryHours = parseInt(document.getElementById('broadcast-expiry').value);
    
    if (!message || message.trim() === '') {
        alert('Please enter a broadcast message');
        return;
    }
    
    try {
        const response = await fetch('/mock/v1/news', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: message,
                priority: priority,
                expires_at: Math.floor(Date.now() / 1000) + (expiryHours * 3600)
            })
        });
        
        if (response.ok) {
            document.getElementById('broadcast-message').value = '';
            loadBroadcasts();
            playSound('Success');
            alert('Broadcast sent successfully');
        } else {
            playSound('DISAPPOINTING_FAILURE');
            alert('Failed to send broadcast');
        }
    } catch (error) {
        console.error('Failed to send broadcast:', error);
        playSound('DISAPPOINTING_FAILURE');
        alert('Failed to send broadcast');
    }
}

async function loadBroadcasts() {
    try {
        const response = await fetch('/mock/v1/news');
        const data = await response.json();
        
        const broadcastList = document.getElementById('broadcast-list');
        
        if (data.message && data.message !== '') {
            const expiryDate = new Date(data.expires_at * 1000);
            const isExpired = expiryDate < new Date();
            
            broadcastList.innerHTML = `
                <div class="broadcast-item">
                    <span class="broadcast-message">${data.message}</span>
                    <div class="broadcast-meta">
                        <span class="broadcast-priority ${data.priority}">${data.priority.toUpperCase()}</span>
                        <span>Expires: ${expiryDate.toLocaleString()}</span>
                        ${isExpired ? '<span style="color: #FF0000;">EXPIRED</span>' : '<span style="color: #00FF00;">ACTIVE</span>'}
                    </div>
                </div>
            `;
        } else {
            broadcastList.innerHTML = '<div class="broadcast-item"><span class="broadcast-message">No active broadcasts</span></div>';
        }
    } catch (error) {
        console.error('Failed to load broadcasts:', error);
        document.getElementById('broadcast-list').innerHTML = '<div class="broadcast-item"><span class="broadcast-message">Failed to load broadcasts</span></div>';
    }
}

async function viewFile(filePath) {
    try {
        const response = await fetch(`/mock/v1/files/view?path=${encodeURIComponent(filePath)}`);
        if (response.ok) {
            const text = await response.text();
            document.getElementById('file-viewer-name').textContent = filePath;
            const contentElement = document.getElementById('file-viewer-content').querySelector('pre');
            contentElement.textContent = '';
            contentElement.textContent = text;
            document.getElementById('file-viewer-panel').style.display = 'block';
            playClick();
        } else {
            alert('Failed to view file');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to view file:', error);
        alert('Failed to view file');
        playSound('DISAPPOINTING_FAILURE');
    }
}

function closeFileViewer() {
    document.getElementById('file-viewer-panel').style.display = 'none';
    playClick();
}

function browseUp() {
    const pathParts = currentBrowsePath.split('/');
    if (pathParts.length > 1) {
        pathParts.pop();
        const parentPath = pathParts.join('/');
        browseFiles(parentPath || '.');
    }
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

// Sound management
let soundCategoryState = {}; // Preserve category state across reloads

async function loadSounds() {
    try {
        const response = await fetch('/mock/v1/sounds');
        const sounds = await response.json();

        console.log('Loaded sounds:', sounds);
        console.log('Total sounds:', sounds.length);

        const soundList = document.getElementById('sound-list-settings');
        if (sounds && sounds.length > 0) {
            // Backend already filters out macOS ._ files, no need to filter here
            
            // Group sounds by category
            const categories = {
                'Click Sounds': sounds.filter(s => s.name.includes('click')),
                'Alerts': sounds.filter(s => s.name.includes('Warning') || s.name.includes('Error') || s.name.includes('Failure')),
                'Success': sounds.filter(s => s.name.includes('Success') || s.name.includes('Access') || s.name.includes('Tada')),
                'Ambient': sounds.filter(s => s.name.includes('ambient') || s.name.includes('background')),
                'UI Sounds': sounds.filter(s => s.name.includes('UI') || s.name.includes('menu') || s.name.includes('hover')),
                'Notifications': sounds.filter(s => s.name.includes('notification') || s.name.includes('alert') || s.name.includes('beep')),
                'Other': sounds.filter(s => !s.name.includes('click') && !s.name.includes('Warning') && !s.name.includes('Error') && !s.name.includes('Failure') && !s.name.includes('Success') && !s.name.includes('Access') && !s.name.includes('Tada') && !s.name.includes('ambient') && !s.name.includes('background') && !s.name.includes('UI') && !s.name.includes('menu') && !s.name.includes('hover') && !s.name.includes('notification') && !s.name.includes('alert') && !s.name.includes('beep'))
            };

            console.log('Categories:', categories);

            let html = '';
            for (const [category, categorySounds] of Object.entries(categories)) {
                if (categorySounds.length > 0) {
                    console.log(`Category ${category}: ${categorySounds.length} sounds`);
                    const categoryId = category.replace(/\s/g, '-');
                    const displayState = soundCategoryState[categoryId] !== undefined ? soundCategoryState[categoryId] : 'block';
                    html += `
                        <div class="sound-category">
                            <h3 onclick="toggleSoundCategory('${category}')">${category} ▼</h3>
                            <div class="sound-category-content" id="category-${categoryId}" style="display: ${displayState};">
                                ${categorySounds.map(sound => `
                                    <div class="sound-item">
                                        <span class="sound-name">${sound.name}</span>
                                        <div class="sound-actions">
                                            <button onclick="playSoundFile('${sound.name}')">PLAY</button>
                                        </div>
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    `;
                }
            }
            soundList.innerHTML = html;
        } else {
            soundList.innerHTML = '<div class="sound-item"><span class="sound-name">No sounds found</span></div>';
        }
    } catch (error) {
        console.error('Failed to load sounds:', error);
        document.getElementById('sound-list').innerHTML = '<div class="sound-item"><span class="sound-name">Failed to load sounds</span></div>';
    }
}

function toggleSoundCategory(category) {
    const categoryId = category.replace(/\s/g, '-');
    const content = document.getElementById(`category-${categoryId}`);
    if (content.style.display === 'none') {
        content.style.display = 'block';
        soundCategoryState[categoryId] = 'block';
    } else {
        content.style.display = 'none';
        soundCategoryState[categoryId] = 'none';
    }
}

function playSoundFile(soundName) {
    playClick();
    playSound(soundName);
}

// Contact management
async function loadContacts() {
    try {
        const response = await fetch('/mock/v1/contacts');
        const data = await response.json();

        const contactList = document.getElementById('contact-list-devices');
        if (data.contacts && data.contacts.length > 0) {
            contactList.innerHTML = data.contacts.map(contact => `
                <div class="contact-item">
                    <span class="contact-name">${contact.display_name} (${contact.id})</span>
                    <div class="contact-actions">
                        <button onclick="deleteContact('${contact.id}')">DELETE</button>
                    </div>
                </div>
            `).join('');
        } else {
            contactList.innerHTML = '<div class="contact-item"><span class="contact-name">No contacts found</span></div>';
        }
    } catch (error) {
        console.error('Failed to load contacts:', error);
        document.getElementById('contact-list').innerHTML = '<div class="contact-item"><span class="contact-name">Failed to load contacts</span></div>';
    }
}

async function addContact() {
    playClick();
    const kairNumber = document.getElementById('new-contact-kair').value;
    const displayName = document.getElementById('new-contact-name').value;

    if (!kairNumber || !displayName) {
        alert('Please enter both K-number and display name');
        playSound('WarningUI');
        return;
    }

    try {
        const response = await fetch('/mock/v1/contacts', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                id: kairNumber,
                display_name: displayName,
                trust_status: 'pending',
                notes: ''
            })
        });

        if (response.ok) {
            alert('Contact added successfully');
            playSound('TadaSuccess');
            document.getElementById('new-contact-kair').value = '';
            document.getElementById('new-contact-name').value = '';
            loadContacts();
        } else {
            alert('Failed to add contact');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to add contact:', error);
        alert('Failed to add contact');
        playSound('DISAPPOINTING_FAILURE');
    }
}

async function deleteContact(contactId) {
    playClick();
    if (!confirm('Are you sure you want to delete this contact?')) {
        return;
    }

    try {
        const response = await fetch(`/mock/v1/contacts/${contactId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            alert('Contact deleted successfully');
            playSound('TadaSuccess');
            loadContacts();
        } else {
            alert('Failed to delete contact');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to delete contact:', error);
        alert('Failed to delete contact');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Update initializeDashboard to load new features
function initializeDashboard() {
    fetchAdminCode();
    fetchDevices();
    updateSystemStats();
    checkTailscaleStatus();
    loadSettings();
    loadSounds();
    loadContacts();
    loadCalling();
    loadFilters();
    loadTelemetry();
    loadNotes();
    loadMedia();
    loadStorage();
    startClock();
    loadCalendar();
    loadTasks();

    // Start auto-reload mechanism
    startAutoReload();

    // Set up periodic refresh for live data
    setInterval(() => {
        fetchDevices();
        checkTailscaleStatus();
        loadTelemetry();
        loadStorage();
        loadCalendar();
        loadTasks();
    }, 5000); // Refresh devices, Tailscale status, telemetry, storage, calendar, and tasks every 5 seconds
}

// Telemetry management
async function loadTelemetry() {
    try {
        const response = await fetch('/mock/v1/telemetry');
        const data = await response.json();

        const telemetryList = document.getElementById('telemetry-list-files');
        if (data.events && data.events.length > 0) {
            telemetryList.innerHTML = data.events.slice(0, 20).map(event => `
                <div class="telemetry-item">
                    <span class="telemetry-name">${event.timestamp} - ${event.type} - ${event.details}</span>
                </div>
            `).join('');
        } else {
            telemetryList.innerHTML = '<div class="telemetry-item"><span class="telemetry-name">No events logged</span></div>';
        }
    } catch (error) {
        console.error('Failed to load telemetry:', error);
        document.getElementById('telemetry-list').innerHTML = '<div class="telemetry-item"><span class="telemetry-name">Failed to load telemetry</span></div>';
    }
}

async function exportTelemetry() {
    playClick();
    try {
        const response = await fetch('/mock/v1/telemetry/export');
        if (response.ok) {
            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'telemetry-export.json';
            a.click();
            playSound('TadaSuccess');
        } else {
            alert('Failed to export telemetry');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to export telemetry:', error);
        alert('Failed to export telemetry');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Notes management
async function loadNotes() {
    try {
        const response = await fetch('/mock/v1/notes');
        const data = await response.json();

        const notesList = document.getElementById('notes-list-files');
        if (data.notes && data.notes.length > 0) {
            notesList.innerHTML = data.notes.map(note => `
                <div class="note-item">
                    <span class="note-name">${note.title}</span>
                    <div class="note-actions">
                        <button onclick="deleteNote('${note.id}')">DELETE</button>
                    </div>
                </div>
            `).join('');
        } else {
            notesList.innerHTML = '<div class="note-item"><span class="note-name">No notes found</span></div>';
        }
    } catch (error) {
        console.error('Failed to load notes:', error);
        document.getElementById('notes-list').innerHTML = '<div class="note-item"><span class="note-name">Failed to load notes</span></div>';
    }
}

async function addNote() {
    playClick();
    const title = document.getElementById('note-title').value;
    const content = document.getElementById('note-content').value;

    if (!title || !content) {
        alert('Please enter both title and content');
        playSound('WarningUI');
        return;
    }

    try {
        const response = await fetch('/mock/v1/notes', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                title: title,
                content: content,
                created_by: 'control_center'
            })
        });

        if (response.ok) {
            alert('Note added successfully');
            playSound('TadaSuccess');
            document.getElementById('note-title').value = '';
            document.getElementById('note-content').value = '';
            loadNotes();
        } else {
            alert('Failed to add note');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to add note:', error);
        alert('Failed to add note');
        playSound('DISAPPOINTING_FAILURE');
    }
}

async function deleteNote(noteId) {
    playClick();
    if (!confirm('Are you sure you want to delete this note?')) {
        return;
    }

    try {
        const response = await fetch(`/mock/v1/notes/${noteId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            alert('Note deleted successfully');
            playSound('TadaSuccess');
            loadNotes();
        } else {
            alert('Failed to delete note');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to delete note:', error);
        alert('Failed to delete note');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Media management
async function loadMedia() {
    try {
        const response = await fetch('/mock/v1/media');
        const data = await response.json();

        const mediaList = document.getElementById('media-list-files');
        if (data.media && data.media.length > 0) {
            // Backend already filters out macOS ._ files, no need to filter here
            mediaList.innerHTML = data.media.map(media => `
                <div class="media-item">
                    <span class="media-name">${media.name} (${media.type})</span>
                    <div class="media-actions">
                        <button onclick="deleteMedia('${media.id}')">DELETE</button>
                    </div>
                </div>
            `).join('');
        } else {
            mediaList.innerHTML = '<div class="media-item"><span class="media-name">No media files found</span></div>';
        }
    } catch (error) {
        console.error('Failed to load media:', error);
        document.getElementById('media-list').innerHTML = '<div class="media-item"><span class="media-name">Failed to load media</span></div>';
    }
}

async function uploadMedia() {
    playClick();
    const fileInput = document.getElementById('media-input');

    if (!fileInput.files.length) {
        alert('Please select a file');
        playSound('WarningUI');
        return;
    }

    const formData = new FormData();
    formData.append('file', fileInput.files[0]);

    try {
        const response = await fetch('/mock/v1/media', {
            method: 'POST',
            body: formData
        });

        if (response.ok) {
            alert('Media uploaded successfully');
            playSound('TadaSuccess');
            fileInput.value = '';
            loadMedia();
        } else {
            alert('Failed to upload media');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to upload media:', error);
        alert('Failed to upload media');
        playSound('DISAPPOINTING_FAILURE');
    }
}

async function deleteMedia(mediaId) {
    playClick();
    if (!confirm('Are you sure you want to delete this media file?')) {
        return;
    }

    try {
        const response = await fetch(`/mock/v1/media/${mediaId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            alert('Media deleted successfully');
            playSound('TadaSuccess');
            loadMedia();
        } else {
            alert('Failed to delete media');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to delete media:', error);
        alert('Failed to delete media');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Storage management
async function loadStorage() {
    try {
        const response = await fetch('/mock/v1/storage');
        const data = await response.json();

        document.getElementById('storage-total').textContent = data.total || '0 MB';
        document.getElementById('storage-used').textContent = data.used || '0 MB';
        document.getElementById('storage-free').textContent = data.free || '0 MB';
        document.getElementById('storage-messages').textContent = data.messages || '0 MB';
        document.getElementById('storage-files').textContent = data.files || '0 MB';
        document.getElementById('storage-media').textContent = data.media || '0 MB';
    } catch (error) {
        console.error('Failed to load storage:', error);
    }
}

async function cleanupStorage() {
    if (!confirm('This will delete:\n- Telemetry events older than 30 days\n- Media files older than 90 days\n\nThis is safe and helps free up storage space.\n\nContinue?')) {
        return;
    }

    try {
        const response = await fetch('/mock/v1/storage/cleanup', {
            method: 'POST'
        });

        if (response.ok) {
            alert('Storage cleanup completed');
            playSound('TadaSuccess');
            loadStorage();
        } else {
            alert('Failed to cleanup storage');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to cleanup storage:', error);
        alert('Failed to cleanup storage');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Clock system
let clockInterval = null;
let clockMode = '12h';

function startClock() {
    updateClock();
    clockInterval = setInterval(updateClock, 1000);
}

function updateClock() {
    const now = new Date();
    let timeString = '';

    if (clockMode === 'utc') {
        timeString = now.toUTCString().split(' ')[4];
    } else if (clockMode === '24h') {
        timeString = now.toLocaleTimeString('en-US', { hour12: false });
    } else {
        timeString = now.toLocaleTimeString('en-US', { hour12: true });
    }

    document.getElementById('system-clock').textContent = timeString;
}

async function updateClockSettings() {
    playClick();
    clockMode = document.getElementById('clock-mode').value;

    try {
        const response = await fetch('/mock/v1/clock/settings', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ mode: clockMode })
        });

        if (response.ok) {
            alert('Clock settings updated');
            playSound('TadaSuccess');
        } else {
            alert('Failed to update clock settings');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to update clock settings:', error);
        alert('Failed to update clock settings');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Calendar management
async function loadCalendar() {
    try {
        const response = await fetch('/mock/v1/calendar');
        const data = await response.json();

        const calendarList = document.getElementById('calendar-list-files');
        if (data.events && data.events.length > 0) {
            calendarList.innerHTML = data.events.map(event => `
                <div class="calendar-item">
                    <span class="calendar-name">${event.title} - ${event.start_time}</span>
                    <div class="calendar-actions">
                        <button onclick="deleteEvent('${event.id}')">DELETE</button>
                    </div>
                </div>
            `).join('');
        } else {
            calendarList.innerHTML = '<div class="calendar-item"><span class="calendar-name">No events found</span></div>';
        }
    } catch (error) {
        console.error('Failed to load calendar:', error);
        document.getElementById('calendar-list').innerHTML = '<div class="calendar-item"><span class="calendar-name">Failed to load calendar</span></div>';
    }
}

async function addEvent() {
    playClick();
    const title = document.getElementById('event-title').value;
    const startTime = document.getElementById('event-start').value;
    const endTime = document.getElementById('event-end').value;

    if (!title || !startTime) {
        alert('Please enter title and start time');
        playSound('WarningUI');
        return;
    }

    try {
        const response = await fetch('/mock/v1/calendar', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                title: title,
                start_time: startTime,
                end_time: endTime,
                created_by: 'control_center'
            })
        });

        if (response.ok) {
            alert('Event added successfully');
            playSound('TadaSuccess');
            document.getElementById('event-title').value = '';
            document.getElementById('event-start').value = '';
            document.getElementById('event-end').value = '';
            loadCalendar();
        } else {
            alert('Failed to add event');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to add event:', error);
        alert('Failed to add event');
        playSound('DISAPPOINTING_FAILURE');
    }
}

async function deleteEvent(eventId) {
    playClick();
    if (!confirm('Are you sure you want to delete this event?')) {
        return;
    }

    try {
        const response = await fetch(`/mock/v1/calendar/${eventId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            alert('Event deleted successfully');
            playSound('TadaSuccess');
            loadCalendar();
        } else {
            alert('Failed to delete event');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to delete event:', error);
        alert('Failed to delete event');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Tasks management
async function loadTasks() {
    try {
        const response = await fetch('/mock/v1/tasks');
        const data = await response.json();

        const taskList = document.getElementById('task-list-files');
        if (data.tasks && data.tasks.length > 0) {
            taskList.innerHTML = data.tasks.map(task => `
                <div class="task-item">
                    <span class="task-name">${task.title} (${task.priority}) - ${task.due_date}</span>
                    <div class="task-actions">
                        <button onclick="deleteTask('${task.id}')">DELETE</button>
                    </div>
                </div>
            `).join('');
        } else {
            taskList.innerHTML = '<div class="task-item"><span class="task-name">No tasks found</span></div>';
        }
    } catch (error) {
        console.error('Failed to load tasks:', error);
        document.getElementById('task-list').innerHTML = '<div class="task-item"><span class="task-name">Failed to load tasks</span></div>';
    }
}

async function addTask() {
    playClick();
    const title = document.getElementById('task-title').value;
    const dueDate = document.getElementById('task-due').value;
    const priority = document.getElementById('task-priority').value;

    if (!title) {
        alert('Please enter title');
        playSound('WarningUI');
        return;
    }

    try {
        const response = await fetch('/mock/v1/tasks', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                title: title,
                due_date: dueDate,
                priority: priority,
                created_by: 'control_center'
            })
        });

        if (response.ok) {
            alert('Task added successfully');
            playSound('TadaSuccess');
            document.getElementById('task-title').value = '';
            document.getElementById('task-due').value = '';
            loadTasks();
        } else {
            alert('Failed to add task');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to add task:', error);
        alert('Failed to add task');
        playSound('DISAPPOINTING_FAILURE');
    }
}

async function deleteTask(taskId) {
    playClick();
    if (!confirm('Are you sure you want to delete this task?')) {
        return;
    }

    try {
        const response = await fetch(`/mock/v1/tasks/${taskId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            alert('Task deleted successfully');
            playSound('TadaSuccess');
            loadTasks();
        } else {
            alert('Failed to delete task');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to delete task:', error);
        alert('Failed to delete task');
        playSound('DISAPPOINTING_FAILURE');
    }
}

// Calling management
let ringtonePlayer = null;
let dialTonePlayer = null;

async function loadCalling() {
    try {
        const response = await fetch('/mock/v1/calling');
        const data = await response.json();

        const callingList = document.getElementById('calling-list-comm');
        if (data.calls && data.calls.length > 0) {
            callingList.innerHTML = data.calls.map(call => `
                <div class="calling-item">
                    <span class="calling-name">${call.kair_number} - ${call.status}</span>
                    <div class="call-actions">
                        <button onclick="endCall('${call.id}', 'normal')">END</button>
                    </div>
                </div>
            `).join('');
        } else {
            callingList.innerHTML = '<div class="calling-item"><span class="calling-name">No active calls</span></div>';
        }
    } catch (error) {
        console.error('Failed to load calls:', error);
        document.getElementById('calling-list').innerHTML = '<div class="calling-item"><span class="calling-name">Failed to load calls</span></div>';
    }
}

async function initiateCall() {
    playClick();
    const kairNumber = document.getElementById('call-kair').value;

    if (!kairNumber || kairNumber === 'K') {
        alert('Please enter a K-number to call');
        playSound('WarningUI');
        return;
    }

    try {
        // Start playing ringtone with loop
        playRingtone();

        const response = await fetch('/mock/v1/calls', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                target_kair: kairNumber,
                initiated_by: 'control_center'
            })
        });

        if (response.ok) {
            alert('Call initiated');
            document.getElementById('call-kair').value = 'K';
            loadCalling();
        } else {
            // Call failed, play call fail sequence
            stopRingtone();
            playCallFailSequence();
            alert('Failed to initiate call');
        }
    } catch (error) {
        console.error('Failed to initiate call:', error);
        // Connection failed, play hangup lost connection
        stopRingtone();
        playSound('hangup_lostconnection');
        alert('Failed to initiate call - connection lost');
    }
}

async function endCall(callId, hangupType = 'normal') {
    playClick();
    if (!confirm('Are you sure you want to end this call?')) {
        return;
    }

    stopRingtone();

    try {
        const response = await fetch(`/mock/v1/calls/${callId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            // Play appropriate hangup sound
            if (hangupType === 'lost_connection') {
                playSound('hangup_lostconnection');
            } else {
                playSound('hangup_normal');
            }
            alert('Call ended');
            loadCalling();
        } else {
            playSound('hangup_lostconnection');
            alert('Failed to end call');
        }
    } catch (error) {
        console.error('Failed to end call:', error);
        playSound('hangup_lostconnection');
        alert('Failed to end call - connection lost');
    }
}

function playRingtone() {
    if (ringtonePlayer) {
        ringtonePlayer.pause();
        ringtonePlayer = null;
    }
    ringtonePlayer = new Audio('/sounds/ringtone.mp3');
    ringtonePlayer.loop = true;
    ringtonePlayer.volume = 1.0;
    ringtonePlayer.play().catch(err => console.log('Ringtone play failed:', err));
}

function stopRingtone() {
    if (ringtonePlayer) {
        ringtonePlayer.pause();
        ringtonePlayer = null;
    }
}

function playCallFailSequence() {
    // Play call fail tone first
    const failTone = new Audio('/sounds/callfailtone.mp3');
    failTone.volume = 1.0;
    failTone.play();
    
    // Then play call fail message after tone completes
    failTone.onended = () => {
        const failMessage = new Audio('/sounds/callfailmessage.mp3');
        failMessage.volume = 1.0;
        failMessage.play();
    };
}

function playDialTone(digit) {
    if (dialTonePlayer) {
        dialTonePlayer.pause();
        dialTonePlayer = null;
    }
    dialTonePlayer = new Audio(`/sounds/Dial_${digit}.mp3`);
    dialTonePlayer.volume = 1.0;
    dialTonePlayer.play().catch(err => console.log('Dial tone play failed:', err));
}

function stopDialTone() {
    if (dialTonePlayer) {
        dialTonePlayer.pause();
        dialTonePlayer = null;
    }
}

// Filtering management
async function loadFilters() {
    try {
        const response = await fetch('/mock/v1/filters');
        const data = await response.json();

        const filterList = document.getElementById('filter-list-comm');
        if (data.filters && data.filters.length > 0) {
            filterList.innerHTML = data.filters.map(filter => `
                <div class="filter-item">
                    <span class="filter-name">${filter.keyword} (${filter.type})</span>
                    <div class="filter-actions">
                        <button onclick="deleteFilter('${filter.id}')">DELETE</button>
                    </div>
                </div>
            `).join('');
        } else {
            filterList.innerHTML = '<div class="filter-item"><span class="filter-name">No filters configured</span></div>';
        }
    } catch (error) {
        console.error('Failed to load filters:', error);
        document.getElementById('filter-list').innerHTML = '<div class="filter-item"><span class="filter-name">Failed to load filters</span></div>';
    }
}

async function addFilter() {
    playClick();
    const keyword = document.getElementById('filter-keyword').value;
    const filterType = document.getElementById('filter-type').value;

    if (!keyword) {
        alert('Please enter a keyword');
        playSound('WarningUI');
        return;
    }

    try {
        const response = await fetch('/mock/v1/filters', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                keyword: keyword,
                type: filterType,
                created_by: 'control_center'
            })
        });

        if (response.ok) {
            alert('Filter added successfully');
            playSound('TadaSuccess');
            document.getElementById('filter-keyword').value = '';
            loadFilters();
        } else {
            alert('Failed to add filter');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to add filter:', error);
        alert('Failed to add filter');
        playSound('DISAPPOINTING_FAILURE');
    }
}

async function deleteFilter(filterId) {
    playClick();
    if (!confirm('Are you sure you want to delete this filter?')) {
        return;
    }

    try {
        const response = await fetch(`/mock/v1/filters/${filterId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            alert('Filter deleted successfully');
            playSound('TadaSuccess');
            loadFilters();
        } else {
            alert('Failed to delete filter');
            playSound('DISAPPOINTING_FAILURE');
        }
    } catch (error) {
        console.error('Failed to delete filter:', error);
        alert('Failed to delete filter');
        playSound('DISAPPOINTING_FAILURE');
    }
}
