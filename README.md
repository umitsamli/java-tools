# JavaTools

Scans JDK and JRE installations on Windows and creates one command per major version, such as `java17.bat`. When several installs share a major version, the newest one is kept.

## Setup

Place `java-init.bat` in a folder and run it once:

```bat
java-init.bat
```

The first run adds that folder to the user PATH. New terminals can then run commands such as `java17` directly. Administrator rights are not required. If the folder is already on PATH, the value is left unchanged.

## Usage

```bat
java-init.bat            lists the Java commands in this folder
java-init.bat -create    scans installations and rewrites the commands
java17 -version          runs a generated command
```

`-create` looks in:

- Java install folders under `Program Files`, `Program Files (x86)`, and `%LOCALAPPDATA%\Programs`
- `%USERPROFILE%\.jdks`, Scoop, and Chocolatey
- `JAVA_HOME`, `PATH`, and the JDK registry keys

The version is read from the install's `release` file when that file exists. `java.exe` is started only when it does not. Oracle `javapath` and `latest` shortcuts, and a JDK's bundled `jre\bin` copy, are skipped.

Generated files stay in this folder. They contain machine-specific paths, so they are not added to the git repository.
