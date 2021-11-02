if has("syntax")
	syntax on
endif

filetype on
filetype indent on

set encoding=utf-8
set ruler
set showcmd
set showmode
set hlsearch
set smartcase
set shiftwidth=4
set tabstop=4
set softtabstop=4
set autoindent
set smartindent
set showmatch
set paste
set nu
set noswapfile
set undofile
set undodir=~/.vim/undo
set splitbelow
set splitright
set mouse=a
" 快速行切换

" 键盘映射
map R :source $MYVIMRC<CR>
map nt :tabe<CR>
map tn :tabn<CR>
map tp :tabp<CR>

" 每次打开文件回到上次关闭文件处
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "no    rmal! g'\"" | endif

set nocompatible
"显示行号"
set number
" 隐藏滚动条"    
set guioptions-=r 
set guioptions-=L
set guioptions-=b
"隐藏顶部标签栏"
set showtabline=0
"设置字体"
set guifont=Monaco:h13         
syntax on   "开启语法高亮"
let g:solarized_termcolors=256  "solarized主题设置在终端下的设置"
set background=dark     "设置背景色"
"colorscheme solarized
set nowrap  "设置不折行"
set fileformat=unix "设置以unix的格式保存文件"
set cindent     "设置C样式的缩进格式"
set tabstop=4   "设置table长度"
set shiftwidth=4        "同上"
set showmatch   "显示匹配的括号"
set scrolloff=5     "距离顶部和底部5行"
set laststatus=2    "命令行为两行"
set fenc=utf-8      "文件编码"
set backspace=2
set mouse-=a    "启用鼠标"
set selection=exclusive
set selectmode=mouse,key
set matchtime=5
set ignorecase      "忽略大小写"
set incsearch
set hlsearch        "高亮搜索项"
set expandtab     "扩展table"
set whichwrap+=<,>,h,l
set autoread
set cursorline      "突出显示当前行"
set cursorcolumn        "突出显示当前列"
set wrap			"设置换行"

"按F5运行python"
map <F5> :Autopep8<CR> :w<CR> :call RunPython()<CR>
function RunPython()
    let mp = &makeprg
    let ef = &errorformat
    let exeFile = expand("%:t")
    setlocal makeprg=python\ -u
    set efm=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m
    silent make %
    copen
    let &makeprg = mp
    let &errorformat = ef
endfunction

filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'Yggdroot/indentLine'
Plugin 'jiangmiao/auto-pairs'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tell-k/vim-autopep8'
Plugin 'preservim/nerdtree'
call vundle#end()
filetype plugin indent on  
let g:pydiction_location = '/mnt/lustre/aifs/home/xl001/.vim/bundle/pydiction/complete-dict'
let g:pydiction_menu_height = 3
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'





" Plugin 'Lokaltog/vim-powerline'
" remove and resume window style
map <Leader>, :call ToggleWindowStyle()<CR>
function! ToggleWindowStyle()
    if &mouse == 'a'
        set nonu nornu mouse=
    else
        set nu mouse=a
    endif
endfunction

map <C-]> :NERDTreeToggle<CR>
