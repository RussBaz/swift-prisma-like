extension Character {
    var isControl: Bool {
        guard let value = asciiValue else { return false }

        return value < 32
    }

    var isASCIILetter: Bool {
        guard let value = asciiValue else { return false }

        return (value > 96 && value < 123) || (value > 64 && value < 91)
    }

    var isASCIINumber: Bool {
        guard let value = asciiValue else { return false }
        return value > 47 && value < 58
    }

    var isWord: Bool {
        guard let value = asciiValue else { return false }

        return value == 137 || (value > 96 && value < 123) || (value > 64 && value < 91) || (value > 47 && value < 58)
    }
}
