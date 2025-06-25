#Requires AutoHotkey v2.0

global isRunning := false
global nextCheckTime := 0
global lastColorName := ""
global lastHex := ""

; ========= config :3 ========
global discordWebhook := ""
global robloxLink := ""
global autoSell := Map(
    "blue", true,
    "purple", true,
    "pink", false,
    "red", false,
    "gold", false
)
global timerInterval := 4500 
; no gamepess = ?ms
; gamepass = 4500 (not tested)
; ============================

AustisticMouse(x2, y2, duration := 7500) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x1, &y1)
    steps := Max(1, duration // 5)
    dx := (x2 - x1) / steps
    dy := (y2 - y1) / steps

    Loop steps {
        x := Round(x1 + (A_Index * dx))
        y := Round(y1 + (A_Index * dy))
        MouseMove(x, y)
    }
    MouseMove(x2, y2) 
}

F8::ToggleLoop()
F1::ManualTrigger("red")
F2::ManualTrigger("gold")

ToggleLoop() {
    global isRunning, nextCheckTime, timerInterval
    isRunning := !isRunning
    if isRunning {
        SetTimer(ClickThenCheck, timerInterval)
        SetTimer(UpdateOverlay, 1000)
        nextCheckTime := A_TickCount + timerInterval
        ShowOverlay("Starting...")
    } else {
        SetTimer(ClickThenCheck, 0)
        SetTimer(UpdateOverlay, 0)
        ShowOverlay("Status: Stopped")
    }
}

ClickThenCheck(*) {
    global nextCheckTime, lastColorName, lastHex, autoSell, isRunning, timerInterval, robloxLink

    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")

    emergencyColor := 0x393B3D
    pixelColor := PixelGetColor(780, 520, "RGB")
    if (pixelColor = emergencyColor) {
        SendAlert()
        Sleep(2500)
        Send("{Alt down}{F4 down}{F4 up}{Alt up}")
        Sleep(500)
        Send("{LWin down}r{LWin up}")
        Sleep(400)
        SendText(robloxLink)
        Send("{Enter}")
        Sleep(26000)
        AustisticMouse(728, 43)
        Sleep(150)
        Click
        AustisticMouse(1300, 500)
        Click
        Sleep(150)
        Click
        Sleep(150)
        Click
        Sleep(150)
        Click
        return
    }

    xCenter := 966
    y := 325
    tolerance := 15
    matchedColor := ""
    detectedHex := ""
    pixelsScanned := 0

    colors := Map(
        "blue", 0x556FF2,
        "purple", 0x8A51F2,
        "pink", 0xCA3BDD,
        "red", 0xDC5B5B,
        "gold", 0xECCB1F
    )

    Loop 50 {
        offset := A_Index - 51
        x := xCenter + offset
        pixelColor := PixelGetColor(x, y, "RGB")
        pixelsScanned++

        for name, refColor in colors {
            if ColorsMatch(pixelColor, refColor, tolerance) {
                matchedColor := name
                detectedHex := Format("0x{:06X}", pixelColor)
                break 2
            }
        }
    }

    if (matchedColor = "") {
        matchedColor := "unknown"
        detectedHex := Format("0x{:06X}", PixelGetColor(xCenter, y, "RGB"))
    }

    lastColorName := matchedColor
    lastHex := detectedHex

    LogMessage(matchedColor, detectedHex)
    nextCheckTime := A_TickCount + timerInterval

    if autoSell.Has(matchedColor) && autoSell[matchedColor] {
        AustisticMouse(890, 360)
        Sleep(150)
        Click
        AustisticMouse(960, 360)
        Sleep(150)
        Click
        AustisticMouse(960, 360)
    } else {
        AustisticMouse(1030, 360)
        Sleep(150)
        Click
        AustisticMouse(960, 360)
    }

    if matchedColor = "gold" {
        SendDiscordGold(matchedColor, "Detected by Script", detectedHex)
    } else if matchedColor = "red" {
        SendDiscordRed(matchedColor, "Detected by Script", detectedHex)
    }

    if isRunning
        SetTimer(ClickThenCheck, timerInterval)
}

ManualTrigger(color) {
    if color = "gold" {
        SendDiscordGold(color, "Manual Trigger", " ")
        LogMessage(color, "Manual")
    } else if color = "red" {
        SendDiscordRed(color, "Manual Trigger", " ")
        LogMessage(color, "Manual")
    }
}

UpdateOverlay(*) {
    global nextCheckTime, lastColorName, lastHex, autoSell
    timeLeft := Max(0, (nextCheckTime - A_TickCount) // 1000)
    text := "Status: Running`nNext in: " . timeLeft . "s`n"
    for color, enabled in autoSell
        text .= Format("Auto-Sell {}: {}`n", color, enabled ? "Enabled" : "Disabled")
    if lastColorName && lastHex {
        text .= "`nLast: " . lastColorName . " (" . lastHex . ")"
    }
    ShowOverlay(text)
}

ColorsMatch(color1, color2, tolerance) {
    r1 := (color1 >> 16) & 0xFF, g1 := (color1 >> 8) & 0xFF, b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF, g2 := (color2 >> 8) & 0xFF, b2 := color2 & 0xFF
    return Abs(r1 - r2) <= tolerance && Abs(g1 - g2) <= tolerance && Abs(b1 - b2) <= tolerance
}

LogMessage(colorName, hexValue) {
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend(Format("[{}] {} ({})`n", timestamp, colorName, hexValue), "hits.jew", "UTF-8")
}

SendDiscordGold(Name, Condition, Value) {
    global discordWebhook
    payload := Format('{"content":null,"embeds":[{"title":"Gold Hit!","description":"**From the land to the sea, Israel will be free!**","color":15518495}]}')
    escapedPayload := StrReplace(payload, '"', '\"')
    cmd := Format('curl -X POST -H "Content-Type: application/json" -d "{}" "{}"', escapedPayload, discordWebhook)
    FileAppend(Format("[{}] {}", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"), cmd) . "`n", "curl.jew", "UTF-8")
    RunWait(cmd, , "Hide")
}

SendDiscordRed(Name, Condition, Value) {
    global discordWebhook
    payload := Format('{"content":null,"embeds":[{"title":"Red Hit!","description":"**Oy Vey!**","color":15548997} ]}')
    escapedPayload := StrReplace(payload, '"', '\"')
    cmd := Format('curl -X POST -H "Content-Type: application/json" -d "{}" "{}"', escapedPayload, discordWebhook)
    FileAppend(Format("[{}] {}", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"), cmd) . "`n", "curl.jew", "UTF-8")
    RunWait(cmd, , "Hide")
}

SendAlert() {
    global discordWebhook
    payload := Format('{"content":null,"embeds":[{"title":"⚠ U GOT DDOSED NIGGA ⚠","description":"**Rejoining ☺**","color":15548997} ]}')
    escapedPayload := StrReplace(payload, '"', '\"')
    cmd := Format('curl -X POST -H "Content-Type: application/json" -d "{}" "{}"', escapedPayload, discordWebhook)
    FileAppend(Format("[{}] {}", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"), cmd) . "`n", "curl.jew", "UTF-8")
    RunWait(cmd, , "Hide")
}

ShowOverlay(text) {
    static overlayGui
    if !IsSet(overlayGui) {
        overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +OwnDialogs")
        overlayGui.BackColor := "Black"
        overlayGui.SetFont("s10 cWhite", "Segoe UI")
        overlayGui.Add("Text", "vStatusText w240 h180", "")
        overlayGui.Show("x1600 y340 NoActivate")
    }
    overlayGui["StatusText"].Text := text
}
