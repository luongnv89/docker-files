" Basic Vim configuration with helpful defaults and plugins
set nocompatible
filetype off

call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
call plug#end()

filetype plugin indent on
syntax on
set background=dark
set number
set relativenumber
set cursorline
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set clipboard=unnamedplus
set wildmenu
set ignorecase
set smartcase
set incsearch
set hlsearch

" Quick toggles
nnoremap <silent> <C-n> :NERDTreeToggle<CR>
nnoremap <silent> <leader>f :Files<CR>

" GitGutter indicators
let g:gitgutter_enabled = 1
