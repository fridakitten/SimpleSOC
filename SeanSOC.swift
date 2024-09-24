import Foundation

// Constants for CPU configuration
let REG_COUNT = 20
let RAM_SIZE = 256 // Size of RAM

// CPU structure
struct CPU {
    var reg: [UInt8] = Array(repeating: 0, count: REG_COUNT)
    var ram: [UInt8] = Array(repeating: 0, count: RAM_SIZE)
    var programCounter: UInt32 = 0
    var running: Bool = false

    mutating func loadProgram(_ program: [UInt8]) {
        for (index, byte) in program.enumerated() {
            if index < RAM_SIZE {
                ram[index] = byte
            } else {
                print("Warning: Program exceeds RAM size.")
                break
            }
        }
        programCounter = 0
        running = true
    }

    mutating func execute() {
        while running {
            let instruction = ram[Int(programCounter)]
            switch instruction {
            case 0x01: // STORE
                let regIndex = Int(ram[Int(programCounter) + 1])
                let value = ram[Int(programCounter) + 2]
                if regIndex < REG_COUNT {
                    reg[regIndex] = value
                } else {
                    print("Error: Invalid register index \(regIndex).")
                    running = false
                }
                programCounter += 3
            case 0x02: // LOAD
                let regIndex = Int(ram[Int(programCounter) + 1])
                let value = ram[Int(programCounter) + 2]
                if regIndex < REG_COUNT {
                    reg[regIndex] = value
                } else {
                    print("Error: Invalid register index \(regIndex).")
                    running = false
                }
                programCounter += 3
            case 0x03: // ADD
                let regDest = Int(ram[Int(programCounter) + 1])
                let regSrc = Int(ram[Int(programCounter) + 2])
                let imm = ram[Int(programCounter) + 3]
                if regDest < REG_COUNT && regSrc < REG_COUNT {
                    reg[regDest] = reg[regDest] &+ reg[regSrc] &+ imm // Using overflow addition
                } else {
                    print("Error: Invalid register index.")
                    running = false
                }
                programCounter += 4
            case 0x04: // SUB
                let regDest = Int(ram[Int(programCounter) + 1])
                let regSrc = Int(ram[Int(programCounter) + 2])
                let imm = ram[Int(programCounter) + 3]
                if regDest < REG_COUNT && regSrc < REG_COUNT {
                    reg[regDest] = reg[regDest] &- reg[regSrc] &- imm // Using overflow subtraction
                } else {
                    print("Error: Invalid register index.")
                    running = false
                }
                programCounter += 4
            case 0x05: // IF
                let regIndex = Int(ram[Int(programCounter) + 1])
                let imm = ram[Int(programCounter) + 2]
                if regIndex < REG_COUNT && reg[regIndex] == imm {
                    programCounter += 3 // Jump to the label address
                } else {
                    programCounter += 3 // Skip jump
                }
            case 0x06: // JMP
                let labelAddress = ram[Int(programCounter) + 1]
                programCounter = UInt32(labelAddress) // Jump to the label address
            case 0x07: // DPR
                let regIndex = Int(ram[Int(programCounter) + 1])
                if regIndex < REG_COUNT {
                    print("Register R\(regIndex): \(reg[regIndex])")
                } else {
                    print("Error: Invalid register index \(regIndex).")
                }
                programCounter += 2
            case 0x00: // EXIT
                print("Program exited.")
                running = false
            default:
                print("Error: Unknown instruction \(instruction).")
                running = false
            }

            // Check for out-of-bounds access
            if programCounter >= UInt32(RAM_SIZE) {
                print("Error: Program counter out of bounds.")
                running = false
            }
        }
    }
}

// Main function to run the CPU with a given binary program
func main() {
    guard CommandLine.argc >= 2 else {
        print("Usage: \(CommandLine.arguments[0]) <program.bin>")
        return
    }

    let binaryFile = CommandLine.arguments[1]

    do {
        // Read the binary program from file
        let data = try Data(contentsOf: URL(fileURLWithPath: binaryFile))
        let program = Array(data)

        // Initialize and load the CPU
        var cpu = CPU()
        cpu.loadProgram(program)

        // Execute the program
        cpu.execute()

        // Print register states
        /*for (index, value) in cpu.reg.enumerated() {
            print("R\(index): \(value)")
        }*/

    } catch {
        print("Error: Unable to open binary file.")
        return
    }
}

// Run the main function
main()
