//
//  SwiftInjectSwiftLintBuildToolPlugin.swift
//  SwiftInject
//
//  Created by Alex.personal on 23/8/25.
//

import Foundation
import PackagePlugin

@main
struct SmartLoggingSwiftLintBuildToolPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {
        guard target is SourceModuleTarget else { return [] }

        // Directorio de trabajo del paquete (donde vive .swiftlint.yml habitualmente)
        let packageDir = context.package.directory.string
        let cacheDir = context.pluginWorkDirectory.string

        // Construimos un comando de shell de login (-l) y modo comando (-c):
        // 1) cd al paquete para que SwiftLint encuentre .swiftlint.yml
        // 2) invocar 'swiftlint' del sistema sin rutas
        // NOTA: no pasamos ficheros individuales; que resuelva la config/paths el propio SwiftLint
        let shell = Path("/bin/sh")

        // Permite inyectar flags opcionales desde el entorno (p. ej., en CI):
        let extra = ProcessInfo.processInfo.environment["SWIFTLINT_OPTIONS"] ?? ""

        let command = """
        cd "\(packageDir)" && \
        swiftlint lint --quiet --cache-path "\(cacheDir)" \(extra)
        """

        // Pasamos el entorno tal cual (sin tocar PATH). La shell de login cargará tu PATH de usuario.
        var env = ProcessInfo.processInfo.environment
        // En algunos entornos de build HOME no está; mejor garantizarlo si existe.
        if env["HOME"] == nil,
           let home = FileManager.default.homeDirectoryForCurrentUser.path.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
           ) {
            env["HOME"] = home
        }

        return [
            .prebuildCommand(
                displayName: "SwiftLint (\(target.name))",
                executable: shell,
                arguments: ["-lc", command], // -l (login) + -c (command)
                environment: env,
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}
