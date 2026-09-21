struct DynastyFactCardModel: Identifiable {
    let value: String
    let unit: String
    let accessibilityLabel: String
    let destination: CalendarDestination

    var id: String {
        destination.id
    }
}
