import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RestaurantListView()
                .tabItem {
                    Label("Restaurants", systemImage: "fork.knife")
                }
            
            RestaurantMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
        }
    }
} 