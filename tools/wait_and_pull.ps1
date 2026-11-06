# 等 Docker 引擎就绪后自动重新拉取 OpenLane 镜像（用新镜像源）
$ErrorActionPreference = "Continue"
$ready = $false
for ($i = 0; $i -lt 42; $i++) {          # 最多等 7 分钟
    Start-Sleep -Seconds 10
    $sock = wsl -d docker-desktop -- sh -c "ls /var/run/docker.sock 2>/dev/null" 2>$null
    if ($sock -match "docker\.sock") {
        Write-Output "[OK] 引擎 socket 就绪 @ $($i*10)s"
        $ready = $true
        break
    }
}
if ($ready) {
    Write-Output "[OK] 开始用新镜像源拉取 efabless/openlane:latest ..."
    docker pull efabless/openlane:latest 2>&1
    Write-Output "[DONE] pull 命令结束 exit=$LASTEXITCODE"
} else {
    Write-Output "[FAIL] 引擎在 7 分钟内未就绪，请人工检查 Docker Desktop 状态"
}
