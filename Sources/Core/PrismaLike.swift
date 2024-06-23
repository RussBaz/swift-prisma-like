// Fields that are of no interest will be generally dropped or ignored by the parser

public enum PrismaLike {
    public struct PrismaName {
        let value: String

        private init(_ value: String) {
            self.value = value
        }

        init?(from value: String) {
            guard let first = value.first else { return nil }
            guard first.isASCIILetter else { return nil }

            let secondPos = value.index(after: value.startIndex)

            guard secondPos != value.endIndex else {
                self.value = value
                return
            }

            guard value[secondPos ... value.endIndex].allSatisfy(\.isWord) else { return nil }

            self.value = value
        }
    }

    public struct Datasource {
        public enum PropertyValue {
            case constant(String)
            case variable(String)
        }

        public enum ProviderType {
            case postgresql
            case sqlite
        }

        let name: PrismaName
        let provider: ProviderType
        let url: PropertyValue
        let comments: [String]
    }

    public struct Generator {
        let name: PrismaName
        let provider: String
        let output: String?
        let comments: [String]
    }

    public struct Enumeration {
        let name: PrismaName
        let values: [String]
        let comments: [String]
    }

    public struct Model {
        public enum SortOrder {
            case ascending
            case descending
        }

        public enum FunctionType {
            // auto is skipped because it is only supported by the MongoDB in Prisma
            case autoincrement
            // sequence is skipped because it is only supported by the CockroachDB in Prisma
            case cuid // will be treated as 'uuid' until cuid2 is implemented in swift or c/c++
            case uuid
            case now
            case dbgenerated(String)
        }

        public struct Field {
            public enum FieldExpression {
                case string(String)
                case number(Int)
                case function(FunctionType)
            }

            public enum ReferentialActionType {
                case cascade
                case restrict
                case noAction
                case setNull
                case setDefault
            }

            public enum NativeDatabaseType {
                public enum PostgresSQL {
                    // String
                    case text
                    case char(UInt)
                    case varChar(UInt)
                    case bit(UInt)
                    case varBit
                    case uuid
                    case xml
                    case inet
                    case citext
                    // Bolean
                    case boolean
                    // Int
                    case integer
                    case smallInt
                    case int
                    case oid
                    // BigInt
                    case bigInt
                    // Float
                    case doublePrecision
                    case real
                    // Decimal
                    case decimal(p: UInt, s: UInt)
                    case money
                    // DateTime
                    case timestamp(UInt)
                    case timestamptz(UInt)
                    case date
                    case time(UInt)
                    case timetz(UInt)
                    // Json
                    case json
                    case jsonB
                    // Bytes
                    case byteA
                }

                case postgres(PostgresSQL)
            }

            public enum FieldAttribute {
                case idAttrbute(map: String?, length: UInt?, sort: SortOrder?, clustered: Bool?)
                case defaultAttrbute(value: FieldExpression, map: String?)
                case uniqueAttrbute(map: String?, length: UInt?, sort: SortOrder?, clustered: Bool?)
                case relationAttrbute(name: String, fields: [PrismaName], references: [PrismaName], map: String?, onUpdate: ReferentialActionType?, onDelete: ReferentialActionType?)
                case mapAttrbute(name: String)
                case updatedAtAttrbute
                case ignoreAttrbute
                case nativeTypeAttribute(NativeDatabaseType)
            }

            public enum ScalarType {
                case string
                case boolean
                case int
                case bigInt
                case float
                case decimal
                case dateTime
                case json
                case bytes
                case unsupported
            }

            public enum FieldType {
                case scalar(ScalarType)
                case relation(PrismaName)
            }

            public enum FieldModifier {
                case optional
                case single
                case list
            }

            let name: PrismaName
            let type: FieldType
            let modifier: FieldModifier
            let attributes: [FieldAttribute]
            let comments: [String]
        }

        public enum ModelAttribute {
            case idAttrbute(fields: [PrismaName], name: String?, map: String?, length: UInt?, sort: SortOrder?, clustered: Bool?)
            case uniqueAttrbute(fields: [PrismaName], name: String?, map: String?, length: UInt?, sort: SortOrder?, clustered: Bool?)
            case indexAttrbute(fields: [PrismaName], name: String?, map: String?, length: UInt?, sort: SortOrder?, clustered: Bool?)
            case mapAttrbute(name: String)
            case ignoreAttrbute
            case schemaAttrbute(name: String)
        }

        let name: PrismaName
        let fields: [Field]
        let attributes: [ModelAttribute]
        let comments: [String]
    }

    /// Losely typed Prisma Schema
    public struct Schema {
        let datasource: Datasource
        let generator: [Generator]
        let models: [Model]
        let enumerations: [Enumeration]
    }
}
