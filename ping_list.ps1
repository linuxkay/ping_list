#!/usr/bin/powershell7

# ファイル名を入力するための関数
function FileName {
    Read-Host -Prompt "Enter file name"
}

# コンピューター名のリストを読み込む
$computers = Get-Content -Path $(FileName)

# 現在の日時から、ファイル名の一部となるタイムスタンプを生成
$timestamp = Get-Date -Format "yyyy_MM_dd_HHmm"
$csvFileName = "ping_result_$timestamp.csv"
$csvFilePath = Join-Path -Path $PSScriptRoot -ChildPath $csvFileName

# チェック中のメッセージを表示
Write-Host "Checking..."

# 並列処理のための最大スレッド数を設定
$maxJobs = 100

# 結果を格納するハッシュテーブル
$results = @{}

# プログレスバーの初期化
$totalComputers = $computers.Count
$progress = 0

# 並列処理でコンピューターのステータスを確認
$computers | ForEach-Object -ThrottleLimit $maxJobs -Parallel {
    $computer = $_
    $ip = $computer.Split(" - ")[0]
    
    # Pingを実行
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $result = $ping.Send($ip, 1000)
        $status = if ($result.Status -eq 'Success') { "Up" } else { "Down" }
    }
    catch {
        $status = "Down"
    }
    
    # 進捗状況を更新
    $progress = $using:progress
    $progress++
    Write-Progress -Activity "Checking computers" -Status "$progress of $using:totalComputers complete" -PercentComplete (($progress / $using:totalComputers) * 100)
    
    # 結果を返す
    [PSCustomObject]@{
        ComputerName = $computer
        Status = $status
    }
} | ForEach-Object {
    $results[$_.ComputerName] = $_.Status
    Write-Host "$($_.ComputerName) is $($_.Status)"
}

# プログレスバーを完了状態に設定
Write-Progress -Activity "Checking computers" -Completed

# 結果を元の順番で配列に格納
$orderedResults = $computers | ForEach-Object {
    [PSCustomObject]@{
        ComputerName = $_
        Status = $results[$_]
    }
}

# 結果をCSVファイルに出力
$orderedResults | Export-Csv -Path $csvFilePath -NoTypeInformation

# CSVファイルの保存場所を表示
Write-Host "File saved at: $csvFilePath"

# ユーザーの入力待ち
$response = Read-Host "Press C and Enter to Close."
$aborted = $response -eq "C"
