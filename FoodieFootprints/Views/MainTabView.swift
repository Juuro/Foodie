import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RestaurantListView()
                .tabItem {
                    Label(String(localized: "Restaurants"), systemImage: "fork.knife")
                }
            
            MapView()
                .tabItem {
                    Label(String(localized: "Map"), systemImage: "map")
                }
            
            StatisticsView()
                .tabItem {
                    Label(String(localized: "Statistics"), systemImage: "chart.bar")
                }
        }
    }
} 