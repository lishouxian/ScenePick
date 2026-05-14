public enum BingImageSelection {
    public static func selectedImage(
        in images: [BingImage],
        selectedID: BingImage.ID?
    ) -> BingImage? {
        guard let selectedID else {
            return images.first
        }

        return images.first { $0.id == selectedID } ?? images.first
    }
}
