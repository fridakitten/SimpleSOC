import Foundation

// Constants
let MAX_PROGRAM_SIZE = 256
let MAX_LABELS = 50
let MAX_LABEL_LENGTH = 20
let MAX_LINE_LENGTH = 100

// Label Structure
struct Label {
    var name: String
    var address: UInt32
}

// Global Variables
var labels: [Label] = []
var program: [UInt8] = []
var programCounter: UInt32 = 0

// Add a label to the labels array
func addLabel(name: String, address: UInt32) {
    if labels.count >= MAX_LABELS {
        print("Error: Too many labels defined.")
        exit(EXIT_FAILURE)
    }
    labels.append(Label(name: name, address: address))
}

// Find the address of a label by name
func findLabelAddress(name: String) -> UInt32 {
    for label in labels {
        if label.name == name {
            return label.address
        }
    }
    print("Error: Label not found: \(name)")
    exit(EXIT_FAILURE)
}

// Convert register name to number
func regToNum(reg: String) -> UInt8 {
    guard reg.starts(with: "R") || reg.starts(with: "r"),
          let regNum = Int(reg.dropFirst()) else {
        print("Error: Invalid register: \(reg)")
        exit(EXIT_FAILURE)
    }
    return UInt8(regNum)
}

// Convert string to UInt8 safely
func safeUInt8(from string: String) -> UInt8? {
    guard let value = Int(string), value >= 0, value <= 255 else {
        return nil
    }
    return UInt8(value)
}

// Parse labels from the assembly code
func parseLabel(line: String, address: UInt32) -> Bool {
    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedLine.hasSuffix(":") {
        let labelName = String(trimmedLine.dropLast())
        addLabel(name: labelName, address: address)
        return true
    }
    return false
}

// First pass to count the instructions and record labels
func firstPass(source: String) {
    let lines = source.split(separator: "\n")
    for line in lines {
        let lineString = String(line)
        if parseLabel(line: lineString, address: programCounter) {
            continue // Skip to next line after adding a label
        }
        // Count instruction size (assumed fixed size for now)
        programCounter += 3 // Adjust based on instruction sizes
    }
}

// Second pass to process instructions
func secondPass(source: String) {
    let lines = source.split(separator: "\n")
    for line in lines {
        let lineString = String(line)
        if parseLabel(line: lineString, address: programCounter) {
            continue // Skip to next line after adding a label
        }

        // Trim whitespace and tabs, then split by space
        let trimmedLine = lineString.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = trimmedLine.split(separator: " ").map { String($0) }
        guard let instruction = tokens.first else { continue }

        switch instruction {
        case "STORE":
            guard tokens.count == 3,
                  let reg = tokens[1].split(separator: ",").first,
                  let immString = tokens[2].split(separator: ",").first,
                  let imm = safeUInt8(from: String(immString)) else {
                print("Error: STORE instruction malformed. Line: \(lineString)")
                exit(EXIT_FAILURE)
            }
            program.append(0x01) // STORE opcode
            program.append(regToNum(reg: String(reg)))
            program.append(imm)
        case "LOAD":
            guard tokens.count == 3,
                  let reg = tokens[1].split(separator: ",").first,
                  let immString = tokens[2].split(separator: ",").first,
                  let imm = safeUInt8(from: String(immString)) else {
                print("Error: LOAD instruction malformed. Line: \(lineString)")
                exit(EXIT_FAILURE)
            }
            program.append(0x02) // LOAD opcode
            program.append(regToNum(reg: String(reg)))
            program.append(imm)
        case "ADD":
            guard tokens.count == 4,
                  let regDest = tokens[1].split(separator: ",").first,
                  let regSrc = tokens[2].split(separator: ",").first,
                  let immString = tokens[3].split(separator: ",").first,
                  let imm = safeUInt8(from: String(immString)) else {
                print("Error: ADD instruction malformed. Line: \(lineString)")
                exit(EXIT_FAILURE)
            }
            program.append(0x03) // ADD opcode
            program.append(regToNum(reg: String(regDest)))
            program.append(regToNum(reg: String(regSrc)))
            program.append(imm)
        case "SUB":
            guard tokens.count == 4,
                  let regDest = tokens[1].split(separator: ",").first,
                  let regSrc = tokens[2].split(separator: ",").first,
                  let immString = tokens[3].split(separator: ",").first,
                  let imm = safeUInt8(from: String(immString)) else {
                print("Error: SUB instruction malformed. Line: \(lineString)")
                exit(EXIT_FAILURE)
            }
            program.append(0x04) // SUB opcode
            program.append(regToNum(reg: String(regDest)))
            program.append(regToNum(reg: String(regSrc)))
            program.append(imm)
        case "IF":
            guard tokens.count == 4,
                  let reg = tokens[1].split(separator: ",").first,
                  let immString = tokens[2].split(separator: ",").first,
                  let label = tokens[3].split(separator: ",").first,
                  let imm = safeUInt8(from: String(immString)) else {
                print("Error: IF instruction malformed. Line: \(lineString)")
                exit(EXIT_FAILURE)
            }
            program.append(0x05) // IF opcode
            program.append(regToNum(reg: String(reg)))
            program.append(imm)
            // Store the label address later
            addLabel(name: String(label), address: programCounter + 3)
        case "JMP":
            guard tokens.count == 2,
                  let label = tokens[1].split(separator: ",").first else {
                print("Error: JMP instruction malformed. Line: \(lineString)")
                exit(EXIT_FAILURE)
            }
            program.append(0x06) // JMP opcode
            // Store the label address later
            addLabel(name: String(label), address: programCounter + 1)
        case "DPR":
            guard tokens.count == 2,
                  let reg = tokens[1].split(separator: ",").first else {
                print("Error: DPR instruction malformed. Line: \(lineString)")
                exit(EXIT_FAILURE)
            }
            program.append(0x07) // DPR opcode
            program.append(regToNum(reg: String(reg)))
        case "EXIT":
            program.append(0x00) // EXIT opcode
        default:
            print("Error: Unknown instruction: \(instruction). Line: \(lineString)")
            exit(EXIT_FAILURE)
        }
    }
}

// Write the binary program to a file
func writeBinary(filename: String) {
    do {
        let data = Data(program)
        try data.write(to: URL(fileURLWithPath: filename))
    } catch {
        print("Error: Unable to write to output file.")
        exit(EXIT_FAILURE)
    }
}

// Main function
func main() {
    guard CommandLine.argc >= 3 else {
        print("Usage: \(CommandLine.arguments[0]) <source.asm> <output.bin>")
        return
    }

    let sourceFile = CommandLine.arguments[1]
    let outputFile = CommandLine.arguments[2]

    do {
        let source = try String(contentsOfFile: sourceFile, encoding: .utf8)
        firstPass(source: source) // First pass for label parsing
        secondPass(source: source) // Second pass for instruction parsing
        writeBinary(filename: outputFile) // Write to binary
    } catch {
        print("Error: Unable to open source file.")
        return
    }
}

// Run the main function
main()
