local lvgl = require("lvgl")
local timer  -- 定义定时器变量
local server = 'http://62.234.26.198:3000/api'

-- 创建根对象
local root = lvgl.Object(nil, {
    w = lvgl.HOR_RES(),
    h = lvgl.VER_RES(),
    align = lvgl.ALIGN.CENTER,
    border_width = 0,
})
root:clear_flag(lvgl.FLAG.SCROLLABLE)
root:add_flag(lvgl.FLAG.EVENT_BUBBLE)

-- 创建文本框
local txt = lvgl.Textarea(root, {
    w = 355,
    h = 200,
    x = 40,
    y = 70,
    text = '',
    bg_color = 160,
    font_size = 40,
    text_color = '#eeeeee'
})

-- 运行
local run_btn = lvgl.Label(root, {
    w = 80,
    h = 80,
    x = 85,
    y = 320,
    text = 'run',
    radius = 10,
    border_width = 1,
    bg_color = 0,
    font_size = 40,
    text_color = '#eeeeee'
})
run_btn:add_flag(lvgl.FLAG.CLICKABLE)
run_btn:onevent(lvgl.EVENT.CLICKED, function(obj, code)
    func()  -- 启动定时器
end)

-- 暂停
local pause_btn = lvgl.Label(root, {
    w = 80,
    h = 80,
    x = 180,
    y = 320,
    text = 'pause',
    radius = 10,
    border_width = 1,
    bg_color = 0,
    font_size = 40,
    text_color = '#eeeeee'
})
pause_btn:add_flag(lvgl.FLAG.CLICKABLE)
pause_btn:onevent(lvgl.EVENT.CLICKED, function(obj, code)
    if timer then
        timer:pause()  -- 暂停定时器
    end
end)

-- 恢复
local resume_btn = lvgl.Label(root, {
    w = 80,
    h = 80,
    x = 275,
    y = 320,
    text = 'resume',
    radius = 10,
    border_width = 1,
    bg_color = 0,
    font_size = 40,
    text_color = '#eeeeee'
})
resume_btn:add_flag(lvgl.FLAG.CLICKABLE)
resume_btn:onevent(lvgl.EVENT.CLICKED, function(obj, code)
    if timer then
        timer:resume()  -- 恢复定时器
    end
end)

function func()
    -- 清空文本框
    txt:set { text = "" }
    
    -- 如果定时器已经存在，直接返回
    if timer then return end
    
    -- 创建定时器
    timer = lvgl.Timer {
        period = 1000,  -- 每秒触发一次
        paused = false,  -- 启动时不暂停
        cb = function()
            -- 从服务器接收命令
            local command = receiveCommandFromServer()
            -- 更新文本框为接收到的响应
            txt:set { text = os.date("%Y-%m-%d %H:%M:%S") .. " : " .. command }
            if command ~= "" then
                -- 执行命令并返回结果
                execAndReturnResult(command)
            end
        end
    }
end

-- 定义接收服务器命令的函数
function receiveCommandFromServer()
    -- 使用curl从服务器获取命令
    local commandUrl = server .. "/get-command"  -- 替换为实际的服务器URL
    local resultFile = "/data/command.txt"
    
    -- 将服务器命令存到本地文件中
    local cmd = string.format('curl -X GET %s > %s', commandUrl, resultFile)
    os.execute(cmd)
    
    -- 读取命令内容
    local command = ""
    local f = io.open(resultFile, "r")
    if f then
        command = f:read("*all")
        f:close()
    end

    return command
end

-- 定义异步执行命令的函数
function execAndReturnResult(command)
    local tempResultFile = "/data/exec_result.txt"  -- 临时存储执行结果的文件

    -- 异步执行命令并将结果输出到文件
    local success, status, code = os.execute(command .. " > " .. tempResultFile)

    -- 读取执行结果并发送回服务器
    local result = ""
    local f = io.open(tempResultFile, "r")
    if f then
        result = f:read("*all")
        f:close()
    end

    -- 使用curl发送执行结果回服务器
    local resultUrl = server .. "/post-result"  -- 替换为实际的服务器URL
    local sendCmd = string.format('curl -X POST -d "success=%s&status=%s&code=%s&result=%s" %s', 
                               tostring(success), status or "", code or "", result, resultUrl)
    os.execute(sendCmd)
end