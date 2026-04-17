import SwiftUI

struct WeatherAppView: View {
    @State private var temperature: String = "72°"
    @State private var condition: String = "Sunny"
    @State private var location: String = "San Francisco"
    @State private var humidity: String = "45%"
    @State private var wind: String = "8 mph"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location
                Text(location.uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                // Main temperature
                Text(temperature)
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(.primary)
                
                // Condition
                Text(condition.uppercased())
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                
                Divider()
                
                // Details
                HStack(spacing: 40) {
                    VStack {
                        Text("HUMIDITY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(humidity)
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    VStack {
                        Text("WIND")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(wind)
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                
                Divider()
                
                // Hourly forecast
                VStack(alignment: .leading, spacing: 10) {
                    Text("HOURLY FORECAST")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            HourlyForecastView(time: "1 PM", temp: "73°", icon: "sunny")
                            HourlyForecastView(time: "2 PM", temp: "74°", icon: "sunny")
                            HourlyForecastView(time: "3 PM", temp: "75°", icon: "partly-cloudy")
                            HourlyForecastView(time: "4 PM", temp: "74°", icon: "partly-cloudy")
                            HourlyForecastView(time: "5 PM", temp: "72°", icon: "cloudy")
                            HourlyForecastView(time: "6 PM", temp: "70°", icon: "cloudy")
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("WEATHER")
    }
}

struct HourlyForecastView: View {
    let time: String
    let temp: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(iconToEmoji(icon))
                .font(.title)
            
            Text(temp)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(width: 60)
    }
    
    private func iconToEmoji(_ icon: String) -> String {
        switch icon.lowercased() {
        case "sunny":
            return "☀️"
        case "partly-cloudy":
            return "⛅"
        case "cloudy":
            return "☁️"
        case "rain":
            return "🌧️"
        case "snow":
            return "❄️"
        case "thunderstorm":
            return "⛈️"
        default:
            return "🌡️"
        }
    }
}

#Preview {
    NavigationView {
        WeatherAppView()
    }
}
