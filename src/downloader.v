import vweb
import net.urllib
import json

struct App {
    vweb.Context
}

fn main() {
    port := 8080
    initial_commands(port)
    vweb.run<App>(8080)
}

pub fn (mut app App) index() vweb.Result {
    first_time_path := join_path(get_app_path(), 'first_time.txt')
    first_time := !exists(first_time_path)
    if first_time {
        create(first_time_path) or { println('Could not write first time file') }
    }
    format := get_format_setting()
    title := 'Video Downloader'
    lqytmp3 := match_then(format, 'lqytmp3', 'checked')
    hqytmp3 := match_then(format, 'hqytmp3', 'checked')
    hqyt := match_then(format, 'hqyt', 'checked')
    urls_map := parse_query(app.req.url)
    urls := urls_map['urls'] or { []string{} }
    return $vweb.html()
}

struct Video {
    format string
    urls []string
}

['/']
[post]
pub fn (mut app App) post() vweb.Result {
    parsed := parse_form(app.req.data)
    data := Video {
        format: parsed['format'][0] or { '' }
        urls: parsed['urls'] or { []string{} }
    }
    start_download(data)
    format := set_format_setting(data.format)
    lqytmp3 := match_then(format, 'lqytmp3', 'checked')
    hqytmp3 := match_then(format, 'hqytmp3', 'checked')
    hqyt := match_then(format, 'hqyt', 'checked')
    return $vweb.html()
}

['/close']
[get]
pub fn (mut app App) close() vweb.Result {
    return $vweb.html()
}

['/close']
[post]
pub fn (mut app App) post_close() {
    exit(0)
}

struct Name {
    name string
}

['/videos']
pub fn (mut app App) videos_video() vweb.Result {
    start := app.req.url.index('url=') or { -1 }
    if start > -1 {
        url := app.req.url.substr(start + 4, app.req.url.len)
        youtube := join_path(get_app_bin_path(), 'youtube-dl.exe')
        result := execute('$youtube --get-filename $url')
        if result.exit_code == 0 {
            name := result.output.trim_space()
            o := Name { name }
            return app.json(json.encode(o))
        }
    }
    return app.json('{"name":"Hello!"}')
}

fn start_download(data Video) {
    youtube := join_path(get_app_bin_path(), 'youtube-dl.exe')
    if exists(youtube) {
        path := join_path(home_dir(), 'Downloads')
        mut args := get_format_args(data.format)
        args << [ '-o', '$path/%(title)s-%(id)s.%(ext)s' ]
        for url in data.urls {
            mut p := new_process(youtube)
            mut cloned_args := args.clone()
            cloned_args << url
            p.set_args(cloned_args)
            p.run()
        }
    }
}

fn get_format_args(format string) []string {
    return match format {
        'lqytmp3' { [ "--extract-audio", "--audio-format", "mp3", "--audio-quality", '9' ] }
        'hqytmp3' { [ "--extract-audio", "--audio-format", "mp3", "--audio-quality", '0' ] }
        'hqyt' { [ "-f", "bestvideo[ext!=mp4]‌​+bestaudio[ext!=mp4]‌​/best[ext!=mp4]" ] }
        else {[]string{}}
    }
}

fn match_then(s1 string, s2 string, s3 string) string {
    return if s1 == s2 { 'checked' } else { '' }
}

pub fn (mut app App) init_once() {
    app.handle_static('static', false)
}

fn initial_commands(port int) {
    mkdir_all(get_app_path()) or {}
    if !update_downloader() {
        if exists('./bin') {
            mv('./bin', get_app_path()) or {}
            update_downloader()
        } else {
            println('install directory does not exist!')
        }
    }

    url := 'http://localhost:$port/'
    execute("explorer $url")
}

fn update_downloader() bool {
    youtube := join_path(get_app_bin_path(), 'youtube-dl.exe')
    if exists(youtube) {
        mut p := new_process(youtube)
        p.set_args(['-U'])
        p.run()
        return true
    }
    return false
}

fn get_app_bin_path() string {
    return join_path(get_app_path(), 'bin')
}

fn set_format_setting(format string) string {
    current_format := get_format_setting()

    if format.len == 0 {
        return  current_format
    }

    if format != current_format {
        write_file(get_format_setting_path(), format) or {}
    }

    return format
}

fn get_format_setting() string {
    return read_file(get_format_setting_path()) or { 'lqytmp3' }
}

fn get_format_setting_path() string {
    return join_path(get_app_path(), 'format-settings.txt')
}

fn get_app_path() string {
    return join_path(home_dir(), '.video-downloader')
}

fn parse_form(body string) map[string][]string {
    words := body.split('&')
    mut form := map[string][]string{}
    for word in words {
        kv := word.split_nth('=', 2)
        if kv.len != 2 {
            continue
        }
        key := urllib.query_unescape(kv[0]) or { '' }
        value := urllib.query_unescape(kv[1]) or { '' }
        if value.len == 0 {
            continue
        }
        if key in form {
            form[key] << value.trim_space()
        } else {
            form[key] = [value.trim_space()]
        }
    }

    return form
}

fn parse_query(query string) map[string][]string {
    index := (query.index('?') or { -1 }) + 1
    mut query_only := ''
    if index > 0 {
        query_only = query.substr(index, query.len)
    } else {
        return map[string][]string{}
    }
    return parse_form(query_only)
}
