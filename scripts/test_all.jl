# iterations/以下のすべてのパッケージ(模範解答と演習)のテストを，パッケージごとに別のプロセスで実行する．

const ROOT = dirname(@__DIR__)

function packages()
    dirs = String[]
    iterations = joinpath(ROOT, "iterations")
    isdir(iterations) || return dirs
    for iteration in sort(readdir(iterations); by = name -> parse(Int, split(name, "-")[end]))
        for kind in ("exercise", "solution")
            dir = joinpath(iterations, iteration, kind)
            isfile(joinpath(dir, "Project.toml")) && push!(dirs, dir)
        end
    end
    return dirs
end

function main()
    failed = String[]
    for dir in packages()
        name = relpath(dir, ROOT)
        println("==> ", name)
        cmd = `$(Base.julia_cmd()) --startup-file=no --project=$dir -e "using Pkg; Pkg.test()"`
        success(pipeline(cmd; stdout = stdout, stderr = stderr)) || push!(failed, name)
    end
    if isempty(failed)
        println("すべてのパッケージのテストが通った．")
    else
        println("テストが通らなかったパッケージ：")
        foreach(name -> println("  ", name), failed)
        exit(1)
    end
end

main()
