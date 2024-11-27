struct MapView: View {
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locations) { location in
            // Keep existing annotation code...
        }
    }
} 