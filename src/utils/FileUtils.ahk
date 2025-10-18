/**
 * 文件操作工具类
 * 提供文件读写、路径处理、格式转换等实用功能
 */

#Requires AutoHotkey v2.0

class FileUtils {
    /**
     * 读取文件内容
     * @param filePath 文件路径
     * @param encoding 文件编码，默认为UTF-8
     * @returns 文件内容
     */
    static ReadFile(filePath, encoding := "UTF-8") {
        if (!FileExist(filePath)) {
            throw Error("文件不存在: " filePath)
        }

        try {
            content := FileRead(filePath, encoding)
            return content
        }
        catch as e {
            throw Error("读取文件失败: " e.Message)
        }
    }

    /**
     * 写入文件内容
     * @param filePath 文件路径
     * @param content 要写入的内容
     * @param encoding 文件编码，默认为UTF-8
     * @param append 是否追加模式，默认为false（覆盖模式）
     */
    static WriteFile(filePath, content, encoding := "UTF-8", append := false) {
        try {
            ; 确保目录存在
            fileDir := this.GetDirectory(filePath)
            if (!DirExist(fileDir)) {
                DirCreate(fileDir)
            }

            ; 写入文件
            FileAppend(content, filePath, encoding)
        }
        catch as e {
            throw Error("写入文件失败: " e.Message)
        }
    }

    /**
     * 追加内容到文件
     * @param filePath 文件路径
     * @param content 要追加的内容
     * @param encoding 文件编码，默认为UTF-8
     */
    static AppendFile(filePath, content, encoding := "UTF-8") {
        this.WriteFile(filePath, content, encoding, true)
    }

    /**
     * 复制文件
     * @param source 源文件路径
     * @param dest 目标文件路径
     * @param overwrite 是否覆盖已存在的文件，默认为true
     */
    static CopyFile(source, dest, overwrite := true) {
        if (!FileExist(source)) {
            throw Error("源文件不存在: " source)
        }

        try {
            if (overwrite || !FileExist(dest)) {
                FileCopy(source, dest, overwrite)
            }
        }
        catch as e {
            throw Error("复制文件失败: " e.Message)
        }
    }

    /**
     * 移动文件
     * @param source 源文件路径
     * @param dest 目标文件路径
     * @param overwrite 是否覆盖已存在的文件，默认为true
     */
    static MoveFile(source, dest, overwrite := true) {
        if (!FileExist(source)) {
            throw Error("源文件不存在: " source)
        }

        try {
            FileMove(source, dest, overwrite)
        }
        catch as e {
            throw Error("移动文件失败: " e.Message)
        }
    }

    /**
     * 删除文件
     * @param filePath 文件路径
     */
    static DeleteFile(filePath) {
        if (!FileExist(filePath)) {
            return false
        }

        try {
            FileDelete(filePath)
            return true
        }
        catch as e {
            throw Error("删除文件失败: " e.Message)
        }
    }

    /**
     * 获取文件大小（字节）
     * @param filePath 文件路径
     * @returns 文件大小，失败返回0
     */
    static GetFileSize(filePath) {
        if (!FileExist(filePath)) {
            return 0
        }

        try {
            return FileGetSize(filePath)
        }
        catch {
            return 0
        }
    }

    /**
     * 获取文件修改时间
     * @param filePath 文件路径
     * @returns 修改时间戳，失败返回0
     */
    static GetFileTime(filePath) {
        if (!FileExist(filePath)) {
            return 0
        }

        try {
            return FileGetTime(filePath, "M")
        }
        catch {
            return 0
        }
    }

    /**
     * 检查文件是否存在
     * @param filePath 文件路径
     * @returns 是否存在
     */
    static FileExists(filePath) {
        return FileExist(filePath) > 0
    }

    /**
     * 检查目录是否存在
     * @param dirPath 目录路径
     * @returns 是否存在
     */
    static DirectoryExists(dirPath) {
        return DirExist(dirPath) > 0
    }

    /**
     * 创建目录（递归创建）
     * @param dirPath 目录路径
     */
    static CreateDirectory(dirPath) {
        try {
            if (!this.DirectoryExists(dirPath)) {
                DirCreate(dirPath)
            }
        }
        catch as e {
            throw Error("创建目录失败: " e.Message)
        }
    }

    /**
     * 删除目录（递归删除）
     * @param dirPath 目录路径
     * @param recursive 是否递归删除，默认为true
     */
    static DeleteDirectory(dirPath, recursive := true) {
        if (!this.DirectoryExists(dirPath)) {
            return false
        }

        try {
            DirDelete(dirPath, recursive)
            return true
        }
        catch as e {
            throw Error("删除目录失败: " e.Message)
        }
    }

    /**
     * 获取文件路径的目录部分
     * @param filePath 文件路径
     * @returns 目录路径
     */
    static GetDirectory(filePath) {
        return RegExReplace(filePath, "\\[^\\]*$", "")
    }

    /**
     * 获取文件名（包含扩展名）
     * @param filePath 文件路径
     * @returns 文件名
     */
    static GetFileName(filePath) {
        return RegExReplace(filePath, ".*\\", "")
    }

    /**
     * 获取文件名（不包含扩展名）
     * @param filePath 文件路径
     * @returns 文件名（无扩展名）
     */
    static GetFileNameWithoutExtension(filePath) {
        fileName := this.GetFileName(filePath)
        return RegExReplace(fileName, "\.[^.]*$", "")
    }

    /**
     * 获取文件扩展名
     * @param filePath 文件路径
     * @returns 文件扩展名（不含点）
     */
    static GetExtension(filePath) {
        fileName := this.GetFileName(filePath)
        return RegExReplace(fileName, ".*\.", "")
    }

    /**
     * 合并路径
     * @param basePath 基础路径
     * @param relativePath 相对路径
     * @returns 合并后的完整路径
     */
    static CombinePath(basePath, relativePath) {
        ; 确保路径格式正确
        basePath := RegExReplace(basePath, "\\+$", "")
        relativePath := RegExReplace(relativePath, "^\\+", "")

        return basePath "\" relativePath
    }

    /**
     * 获取相对路径
     * @param basePath 基础路径
     * @param fullPath 完整路径
     * @returns 相对路径
     */
    static GetRelativePath(basePath, fullPath) {
        basePath := RegExReplace(basePath, "\\$", "")
        fullPath := RegExReplace(fullPath, "\\$", "")

        if (SubStr(fullPath, 1, StrLen(basePath)) = basePath) {
            return SubStr(fullPath, StrLen(basePath) + 2)
        }

        return fullPath
    }

    /**
     * 格式化文件大小为人类可读格式
     * @param bytes 字节数
     * @returns 格式化的文件大小字符串
     */
    static FormatFileSize(bytes) {
        static units := ["B", "KB", "MB", "GB", "TB"]

        if (bytes = 0) {
            return "0 B"
        }

        index := 0
        size := bytes

        while (size >= 1024 && index < units.Length - 1) {
            size /= 1024
            index++
        }

        if (index = 0) {
            return Format("{:.0f} {}", size, units[index])
        }
        else {
            return Format("{:.2f} {}", size, units[index])
        }
    }

    /**
     * 读取JSON文件
     * @param filePath JSON文件路径
     * @returns 解析后的对象
     */
    static ReadJson(filePath) {
        content := this.ReadFile(filePath)
        try {
            return JSON.Parse(content)
        }
        catch as e {
            throw Error("JSON解析失败: " e.Message)
        }
    }

    /**
     * 写入JSON文件
     * @param filePath JSON文件路径
     * @param data 要写入的数据
     * @param indent 缩进空格数，默认为2
     */
    static WriteJson(filePath, data, indent := 2) {
        try {
            jsonStr := JSON.Stringify(data, indent)
            this.WriteFile(filePath, jsonStr)
        }
        catch as e {
            throw Error("JSON序列化失败: " e.Message)
        }
    }

    /**
     * 读取INI文件到一个Map对象
     * @param filePath INI文件路径
     * @returns 包含所有配置的Map对象
     */
    static ReadIni(filePath) {
        if (!this.FileExists(filePath)) {
            throw Error("INI文件不存在: " filePath)
        }

        config := Map()

        try {
            ; 读取所有段落
            sections := IniRead(filePath)

            loop parse sections, "`n" {
                if (A_LoopField = "") {
                    continue
                }

                section := A_LoopField
                config[section] := Map()

                ; 读取段落内的所有键值对
                keys := IniRead(filePath, section)

                loop parse keys, "`n" {
                    if (A_LoopField = "") {
                        continue
                    }

                    key := A_LoopField
                    value := IniRead(filePath, section, key)
                    config[section][key] := value
                }
            }

            return config
        }
        catch as e {
            throw Error("读取INI文件失败: " e.Message)
        }
    }

    /**
     * 写入Map对象到INI文件
     * @param filePath INI文件路径
     * @param config 配置Map对象
     */
    static WriteIni(filePath, config) {
        try {
            for section, values in config {
                for key, value in values {
                    IniWrite(value, filePath, section, key)
                }
            }
        }
        catch as e {
            throw Error("写入INI文件失败: " e.Message)
        }
    }

    /**
     * 列出目录中的文件
     * @param dirPath 目录路径
     * @param pattern 文件匹配模式，默认为"*"
     * @param recursive 是否递归搜索，默认为false
     * @returns 文件列表数组
     */
    static ListFiles(dirPath, pattern := "*", recursive := false) {
        files := []

        if (!this.DirectoryExists(dirPath)) {
            return files
        }

        try {
            loop files dirPath "\" pattern, recursive ? "R" : "" {
                files.Push(A_LoopFileFullPath)
            }
        }
        catch as e {
            throw Error("列出文件失败: " e.Message)
        }

        return files
    }

    /**
     * 列出目录中的子目录
     * @param dirPath 目录路径
     * @param recursive 是否递归搜索，默认为false
     * @returns 目录列表数组
     */
    static ListDirectories(dirPath, recursive := false) {
        dirs := []

        if (!this.DirectoryExists(dirPath)) {
            return dirs
        }

        try {
            loop files dirPath "\*", "D" (recursive ? "R" : "") {
                dirs.Push(A_LoopFileFullPath)
            }
        }
        catch as e {
            throw Error("列出目录失败: " e.Message)
        }

        return dirs
    }

    /**
     * 检查路径是否为绝对路径
     * @param path 路径字符串
     * @returns 是否为绝对路径
     */
    static IsAbsolutePath(path) {
        return RegExMatch(path, "^[A-Za-z]:\\") > 0
    }

    /**
     * 获取临时文件路径
     * @param extension 文件扩展名，默认为"tmp"
     * @returns 临时文件路径
     */
    static GetTempFile(extension := "tmp") {
        tempDir := A_Temp
        fileName := Format("{}.{}", A_Now, extension)
        return this.CombinePath(tempDir, fileName)
    }

    /**
     * 清空目录内容
     * @param dirPath 目录路径
     * @param pattern 文件匹配模式，默认为"*"
     */
    static ClearDirectory(dirPath, pattern := "*") {
        if (!this.DirectoryExists(dirPath)) {
            return false
        }

        try {
            loop files dirPath "\" pattern {
                FileDelete(A_LoopFileFullPath)
            }
            return true
        }
        catch as e {
            throw Error("清空目录失败: " e.Message)
        }
    }
}

; 便捷函数
ReadFile(filePath, encoding := "UTF-8") => FileUtils.ReadFile(filePath, encoding)
WriteFile(filePath, content, encoding := "UTF-8") => FileUtils.WriteFile(filePath, content, encoding)
FileExists(filePath) => FileUtils.FileExists(filePath)
DirectoryExists(dirPath) => FileUtils.DirectoryExists(dirPath)
GetFileSize(filePath) => FileUtils.GetFileSize(filePath)