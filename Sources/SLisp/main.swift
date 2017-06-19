import SLispCore

let repl = try Repl()

do {
    try repl?.mainLoop()
} catch {
    print(error)
}
