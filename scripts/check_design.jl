# 設計文書を検査する．
#
# 1. 図の構文：Markdownの```mermaidブロックが，このコースで使うflowchartの書き方に従っているか．
# 2. 依存図とコード：design/modules.mdの矢印と，src/*.jlのusing/importが一致するか．
# 3. 誤差仕様書と公開API：design/error-spec.mdの表の関数と，StableNumericsがexportする関数が一致するか．
#    表の「検証するテスト」の列に書いたテストファイルが存在するか．
#
# 使い方：julia scripts/check_design.jl [パッケージのディレクトリ...]
# 引数を省略すると，リポジトリのすべてのMarkdownの図の構文と，Iteration 0の演習を除く
# すべてのパッケージを検査する．

const ROOT = dirname(@__DIR__)
const IDENT = raw"[A-Za-z_][A-Za-z0-9_]*"

struct Diagram
    nodes::Set{String}
    edges::Set{Pair{String,String}}
end

"Markdownから```mermaidブロックを取り出し，(開始行番号, 行のベクトル)の組の列を返す．"
function mermaid_blocks(path)
    blocks = Tuple{Int,Vector{String}}[]
    lines = readlines(path)
    i = 1
    while i <= length(lines)
        if strip(lines[i]) == "```mermaid"
            start = i + 1
            j = start
            while j <= length(lines) && strip(lines[j]) != "```"
                j += 1
            end
            push!(blocks, (start, lines[start:j-1]))
            i = j
        end
        i += 1
    end
    return blocks
end

"flowchartを解析する．構文の誤りはerrorsに加える．"
function parse_flowchart(path, start, lines, errors)
    nodes = Set{String}()
    edges = Set{Pair{String,String}}()
    header_seen = false
    for (offset, raw) in enumerate(lines)
        line = strip(raw)
        lineno = start + offset - 1
        (isempty(line) || startswith(line, "%%")) && continue
        if !header_seen
            if occursin(r"^flowchart\s+(LR|RL|TB|TD|BT)$", line)
                header_seen = true
            else
                push!(errors, "$(path):$(lineno): 図はflowchart LR(またはTB/TD/RL/BT)で始める：$(line)")
            end
            continue
        end
        if (m = match(Regex("^($(IDENT))\\s*-->\\s*($(IDENT))\$"), line)) !== nothing
            push!(nodes, m[1], m[2])
            push!(edges, m[1] => m[2])
        elseif (m = match(Regex("^($(IDENT))\$"), line)) !== nothing
            push!(nodes, m[1])
        else
            push!(errors, "$(path):$(lineno): 解釈できない行(使えるのは「A --> B」と「A」だけ)：$(line)")
        end
    end
    header_seen || push!(errors, "$(path):$(start): 空の図")
    return Diagram(nodes, edges)
end

"src/*.jlのモジュールと，using/importによる依存を集める．"
function code_dependencies(pkg)
    nodes = Set{String}()
    edges = Set{Pair{String,String}}()
    src = joinpath(pkg, "src")
    for file in sort(filter(endswith(".jl"), readdir(src)))
        text = read(joinpath(src, file), String)
        m = match(Regex("^module\\s+($(IDENT))", "m"), text)
        m === nothing && continue
        name = m[1]
        push!(nodes, name)
        for line in eachline(IOBuffer(text))
            u = match(r"^\s*(?:using|import)\s+(.*)$", line)
            u === nothing && continue
            items = u[1]
            # 「using ..A: f, g」の形では，コロンより前の1つだけがモジュールである．
            occursin(':', items) && (items = split(items, ':')[1])
            for item in split(items, ',')
                d = match(Regex("^\\s*\\.{1,2}($(IDENT))"), item)
                d === nothing || push!(edges, name => d[1])
            end
        end
    end
    return Diagram(nodes, edges)
end

"src/StableNumerics.jlのexport文から，公開する関数の名前(小文字で始まるもの)を集める．"
function exported_functions(pkg)
    names = Set{String}()
    for line in eachline(joinpath(pkg, "src", "StableNumerics.jl"))
        m = match(r"^\s*export\s+(.*)$", line)
        m === nothing && continue
        for name in split(m[1], ',')
            name = strip(name)
            !isempty(name) && islowercase(first(name)) && push!(names, name)
        end
    end
    return names
end

"誤差仕様書の表から，(関数名, テストファイルの一覧)を集める．"
function error_spec_rows(path)
    rows = Dict{String,Vector{String}}()
    for line in eachline(path)
        startswith(strip(line), "|") || continue
        cells = strip.(split(strip(strip(line), '|'), '|'))
        m = match(Regex("^`($(IDENT))`\$"), first(cells))
        m === nothing && continue
        rows[m[1]] = [t.match for t in eachmatch(r"test/[A-Za-z0-9_/]+\.jl", last(cells))]
    end
    return rows
end

function report_difference(errors, path, label_only_a, a, label_only_b, b)
    for x in sort(collect(setdiff(a, b)); by = string)
        push!(errors, "$(path): $(label_only_a)：$(x)")
    end
    for x in sort(collect(setdiff(b, a)); by = string)
        push!(errors, "$(path): $(label_only_b)：$(x)")
    end
end

function check_package(pkg, errors)
    modules_md = joinpath(pkg, "design", "modules.md")
    blocks = isfile(modules_md) ? mermaid_blocks(modules_md) : []
    if length(blocks) != 1
        push!(errors, "$(modules_md): 依存図(```mermaidのブロック)をちょうど1つ書く")
    else
        start, lines = only(blocks)
        diagram = parse_flowchart(modules_md, start, lines, errors)
        code = code_dependencies(pkg)
        report_difference(errors, modules_md, "図にだけあるモジュール", diagram.nodes, "コードにだけあるモジュール", code.nodes)
        report_difference(errors, modules_md, "図にだけある依存", diagram.edges, "コードにだけある依存", code.edges)
    end

    spec = joinpath(pkg, "design", "error-spec.md")
    if !isfile(spec)
        push!(errors, "$(spec): 誤差仕様書がない")
    else
        rows = error_spec_rows(spec)
        report_difference(errors, spec, "表にだけある関数", Set(keys(rows)), "表にない公開関数", exported_functions(pkg))
        for (name, tests) in sort(collect(rows))
            isempty(tests) && push!(errors, "$(spec): `$(name)`の検証するテストが書かれていない")
            for test in tests
                isfile(joinpath(pkg, test)) || push!(errors, "$(spec): `$(name)`のテスト$(test)が存在しない")
            end
        end
    end
end

function default_packages()
    dirs = String[]
    iterations = joinpath(ROOT, "iterations")
    isdir(iterations) || return dirs
    for iteration in readdir(iterations)
        for kind in ("exercise", "solution")
            (iteration, kind) == ("iteration-0", "exercise") && continue
            dir = joinpath(iterations, iteration, kind)
            isdir(dir) && push!(dirs, dir)
        end
    end
    return dirs
end

function markdown_files()
    files = readlines(Cmd(`git ls-files -co --exclude-standard -- '*.md'`; dir = ROOT))
    return [joinpath(ROOT, f) for f in files if isfile(joinpath(ROOT, f))]
end

function main(args)
    errors = String[]
    if isempty(args)
        for file in markdown_files(), (start, lines) in mermaid_blocks(file)
            parse_flowchart(relpath(file, ROOT), start, lines, errors)
        end
        packages = default_packages()
    else
        packages = [abspath(arg) for arg in args]
        for pkg in packages, file in (joinpath(pkg, "design", "modules.md"),)
            isfile(file) || continue
            for (start, lines) in mermaid_blocks(file)
                parse_flowchart(relpath(file, ROOT), start, lines, errors)
            end
        end
    end
    for pkg in packages
        check_package(relpath(pkg, ROOT), errors)
    end
    if isempty(errors)
        println("設計文書の検査に通った(", length(packages), "パッケージ)．")
    else
        foreach(println, unique(errors))
        exit(1)
    end
end

cd(() -> main(ARGS), ROOT)
