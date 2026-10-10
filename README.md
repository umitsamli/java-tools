# JavaTools

Windows üzerinde kurulu JDK ve JRE sürümlerini tarar. Her ana sürüm için `java17.bat` gibi bir komut üretir. Aynı ana sürümden birden fazla kurulum varsa en yenisi kullanılır.

## Kurulum

`java-init.bat` dosyasını bir klasöre koyun ve bir kez çalıştırın:

```bat
java-init.bat
```

İlk çalıştırmada bu klasör kullanıcı PATH ortam değişkenine eklenir. Yeni açılan terminallerde `java17` gibi komutlar doğrudan çalışır. Yönetici izni gerekmez. PATH zaten bu klasörü içeriyorsa yeniden yazılmaz.

## Kullanim

```bat
java-init.bat            bulunan java komutlarini listeler
java-init.bat -create    kurulumlari tarar ve komutlari yeniden yazar
java17 -version          olusan komutu calistirir
```

`-create` su kaynaklara bakar:

- `Program Files`, `Program Files (x86)` ve `%LOCALAPPDATA%\Programs` altinda Java kurulum klasorleri
- `%USERPROFILE%\.jdks`, Scoop ve Chocolatey
- `JAVA_HOME`, `PATH` ve JDK kayit defteri anahtarlari

Surum, mumkunse kurulumdaki `release` dosyasindan okunur. `java.exe` yalnizca bu dosya yoksa calistirilir. Oracle `javapath` ve `latest` kisayollari ile JDK icine gomulu `jre\bin` kopyalari atlanir.

Uretilen dosyalar bu klasorde kalir ve makineye ozel olduklari icin git deposuna eklenmez.
