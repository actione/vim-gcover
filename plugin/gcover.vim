if !exists("g:auto_gcov_marker_line_covered")
    let g:auto_gcov_marker_line_covered = '✓'
endif
if !exists("g:auto_gcov_marker_line_uncovered")
    let g:auto_gcov_marker_line_uncovered = '✘'
endif

if !hlexists('GcovLineCovered')
    highlight GCovLineCovered ctermfg=green guifg=green
endif
if !hlexists('GcovLineUncovered')
    highlight GCovLineUncovered ctermfg=red guifg=red
endif

if !exists("g:gcov_path")
	let g:gcov_path = '/home/huaweil/build/cutensornet/projectbuild'
endif

if !exists("g:project_path")
	let g:project_path = '/home/huaweil/project/cuquantum-cutensornet/cuquantum/tensor_network'
endif

function s:clearGcov()
	exe ":sign unplace *"
endfunction

" 只支持单个文件的方案
function s:showGcov()
    " exe ":sign unplace *"
	call s:clearGcov()

    exe ":sign define gcov_line_covered texthl=GcovLineCovered text=" . g:auto_gcov_marker_line_covered
    exe ":sign define gcov_line_uncovered texthl=GcovLineUncovered text=" . g:auto_gcov_marker_line_uncovered

	let l:curr_file_name = expand('%:t')
	" get all gcda file and dump by gcov binary
	let l:gcda_files = split(globpath(g:gcov_path, "**/*.gcda"), '\n')
	if len(l:gcda_files) == 0
		echo "no gcda files in current path " . g:gcov_path
	endif
	let l:tmp_gcov_dir = g:gcov_path . "/tmp"
	if filereadable(tmp_gcov_dir . '/' . l:curr_file_name . ".gcov")
		call delete(l:tmp_gcov_dir . '/' . l:curr_file_name . ".gcov")
	endif
	call mkdir(l:tmp_gcov_dir, "p", 0700)
	" if filereadable(l:tmp_gcov_dir . expand('%:t') . ".gcov")
	" 	delete(l:tmp_gcov_dir . expand('%:t') . ".gcov")
	" endif

	for gcda_file in l:gcda_files
		silent exe '!(cd ' . l:tmp_gcov_dir . '; gcov ' . gcda_file . ') > /dev/null'
	endfor

	" parse gcov file to apply source file
	let l:gcov_files = split(globpath(l:tmp_gcov_dir, "**/" . l:curr_file_name . ".gcov"), '\n')
	if len(l:gcov_files) == 0
		echo "no gcov files in current tmp path"
	elseif len(l:gcov_files) != 1
		echo "have multiple gcov files"
	endif

	for file in l:gcov_files

		" " check if this file is in source file path set
		" let l:file_name = split(file, '/')[-1]
		" let l:file_name_tmp = l:file_name[0:-6] " file_name need be identiy in the project
		" let l:target_source_files = split(globpath(g:project_path, "**/" . l:file_name_tmp), '\n')
		" if len(target_source_files) != 1
		" 	continue
		" endif
		" let l:target_source_file = l:target_source_files[0]

		try
			let l:gcov_file = readfile(file)
		catch
			echo "Failed to read file"
			continue
		endtry


		for line in l:gcov_file
			let items = split(line, ':')
			if len(items) < 2
				continue
			endif
			let type = items[0]
			let line_number = str2nr(items[1])
			if type =~ '-$'
				continue
			elseif type =~ '##$'
                exe ":sign place " . line_number . " line=" . line_number . " name=gcov_line_uncovered file=" . expand('%:p')
			elseif type =~ '==$'
                exe ":sign place " . line_number. " line=" . line_number . " name=gcov_line_uncovered file=" . expand('%:p')
			else
                exe ":sign place " . line_number. " line=" . line_number . " name=gcov_line_covered file=" . expand('%:p')
			endif
		endfor
	endfor
endfunction

command! -bang -nargs=0 GcovShow call s:showGcov()
command! -bang -nargs=0 GcovClear call s:clearGcov()
