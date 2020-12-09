let s:hostname = trim(system('hostname'))
let s:should_install_coc = s:hostname == 'khitomer'

call plug#begin('~/.local/share/nvim/plugged')

" Base plugins
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'editorconfig/editorconfig-vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tpope/vim-fugitive'
" Plug 'dstein64/vim-startuptime'
Plug 'tmsvg/pear-tree'  " Auto parantheses

" vim-stay adds automated view session creation and restoration whenever
" editing a buffer, across Vim sessions and window life cycles.
Plug 'zhimsel/vim-stay'

" Languages
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install' }

" UI
Plug 'tpope/vim-vinegar'
Plug 'itchyny/lightline.vim'
if s:should_install_coc
  Plug 'josa42/vim-lightline-coc'
endif
Plug 'itchyny/vim-gitbranch'
Plug 'liuchengxu/vim-clap', { 'do': ':Clap install-binary' }
Plug 'liuchengxu/vista.vim'  " Code structure view

if has("nvim")
  " https://github.com/lambdalisue/fern.vim/issues/120
  " https://github.com/neovim/neovim/issues/12587
  Plug 'antoinemadec/FixCursorHold.nvim'
endif
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/fern-git-status.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'

Plug 'kyazdani42/nvim-web-devicons'
Plug 'romgrk/barbar.nvim'

if has('nvim') || has('patch-8.0.902')
  Plug 'mhinz/vim-signify'
else
  Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
endif

" COC
if s:should_install_coc
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
  Plug 'neoclide/coc-eslint', {'do': 'yarn install --frozen-lockfile'}
  Plug 'neoclide/coc-prettier', {'do': 'yarn install --frozen-lockfile'}
  Plug 'neoclide/coc-json', { 'do': 'yarn install --frozen-lockfile' }
  Plug 'neoclide/coc-yaml', { 'do': 'yarn install --frozen-lockfile' }
  Plug 'neoclide/coc-solargraph', { 'do': 'yarn install --frozen-lockfile' }
  Plug 'neoclide/coc-css', { 'do': 'yarn install --frozen-lockfile' }
  Plug 'fannheyward/coc-pyright', { 'do': 'yarn install --frozen-lockfile' }
  Plug 'elixir-lsp/coc-elixir', {'do': 'yarn install && yarn prepack'}
  Plug 'iamcco/coc-vimlsp', { 'do': 'yarn install --frozen-lockfile' }
  Plug 'iamcco/coc-diagnostic', { 'do': 'yarn install --frozen-lockfile' }
  Plug 'fannheyward/coc-rust-analyzer', { 'do': 'yarn install --frozen-lockfile' }
endif

" Treesitter
if has('nvim-0.5')
  Plug 'nvim-treesitter/nvim-treesitter'
  " Plug 'nvim-treesitter/playground'
endif

" Disabled plugs and why

" Plug 'Konfekt/FastFold'
" Disabled because treesitter should handle this way better

" Plug 'junegunn/fzf'
" Plug 'junegunn/fzf.vim'
" Replaced by vim-clap

" Themes
" Plug 'drewtempelmeyer/palenight.vim'
" Plug 'arcticicestudio/nord-vim'
" Plug 'NLKNguyen/papercolor-theme'
" Plug 'ayu-theme/ayu-vim'
" Plug 'dracula/vim', { 'as': 'dracula' }
" Plug 'lifepillar/vim-solarized8'
Plug 'bluz71/vim-nightfly-guicolors'

call plug#end()

set termguicolors

" set background=dark
" color nord

" set background=dark
" color palenight
" let g:airline_theme = "palenight"
" let g:palenight_terminal_italics=1

" set background=light
" color PaperColor

" set background=light
" let ayucolor="light"
" color ayu

" set background=light
" color solarized8

" color dracula
" let g:airline_theme = 'dracula'

set background=dark
colorscheme nightfly

" let g:nvcode_termcolors=256
" set background=dark
" colorscheme nvcode

" lightline
let g:lightline = {
\  'colorscheme': 'nightfly',
\  'active': {
\    'left': [ [ 'mode', 'paste' ], [ 'coc_errors', 'coc_warnings', 'coc_ok' ], [ 'gitbranch', 'readonly', 'filename', 'modified' ], [ 'coc_status' ] ]
\  },
\  'component_function': {
\     'gitbranch': 'gitbranch#name',
\     'filetype': 'LightlineFiletype',
\  }
\}
if s:should_install_coc
  call lightline#coc#register()
end

function! LightlineFiletype()
  return &filetype !=# '' ? trim(&filetype . ' ' . nerdfont#find()) : 'no ft'
endfunction

if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" UI
set number " show line numbers
set showcmd " show command in bottom bar (maybe useless because of airline?)
set cursorline " highlight current line
set wildmenu " visual autocomplete for command menu
set lazyredraw " redraw only when we need to.
set showmatch " highlight matching [{()}]

" Update diagnostic messages more often
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Search
set incsearch " search as characters are entered
set hlsearch " highlight matches

" Configure <Leader> to SPACE
let mapleader = " "

" Enable mouse mode
set mouse=a

" Whitespaces
match Error /\s\+$/
match Error /^\t\+/

" Indentation configuration
set tabstop=2 shiftwidth=2 expandtab

" Avoid syntax highlighting for very long lines (default 3000)
set synmaxcol=300

" Relative line numbers
set rnu

set nofoldenable " don't auto fold every fold

" airline configuration
let g:airline_powerline_fonts = 1
let g:airline_highlighting_cache = 1
" let g:airline_extensions = []

" vim-stay
set viewoptions=cursor,folds,slash,unix

" Frequently used shortcuts for clap
nnoremap <silent> <Leader><Space> :<C-u>Clap! files<CR>
nnoremap <silent> <Leader>b :<C-u>Clap buffers<CR>

" Position clap relative to editor, not current window
let g:clap_layout = { 'relative': 'editor' }

" tell it to use an undo file
set undofile

let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']

let g:fern#disable_default_mappings = 1
let g:fern#disable_drawer_smart_quit = 1
let g:fern#renderer = "nerdfont"

noremap <silent> <Leader>d :Fern . -drawer -width=35 -toggle<CR><C-w>=
noremap <silent> <Leader>f :Fern . -drawer -reveal=% -width=35<CR><C-w>=
noremap <silent> <Leader>. :Fern %:h -drawer -width=35<CR><C-w>=

function! FernInit() abort
  nmap <buffer><expr>
        \ <Plug>(fern-my-open-expand-collapse)
        \ fern#smart#leaf(
        \   "\<Plug>(fern-action-open:select)",
        \   "\<Plug>(fern-action-expand)",
        \   "\<Plug>(fern-action-collapse)",
        \ )
  nmap <buffer> <CR> <Plug>(fern-my-open-expand-collapse)
  nmap <buffer> <2-LeftMouse> <Plug>(fern-my-open-expand-collapse)
  nmap <buffer> N <Plug>(fern-action-new-file)
  nmap <buffer> K <Plug>(fern-action-new-dir)
  nmap <buffer> D <Plug>(fern-action-remove)
  nmap <buffer> M <Plug>(fern-action-move)
  nmap <buffer> H <Plug>(fern-action-hidden-toggle)j
  nmap <buffer> R <Plug>(fern-action-reload)
  nmap <buffer> m <Plug>(fern-action-mark-toggle)j
  nmap <buffer> s <Plug>(fern-action-open:split)
  nmap <buffer> v <Plug>(fern-action-open:vsplit)
  nmap <buffer><nowait> < <Plug>(fern-action-leave)
  nmap <buffer><nowait> > <Plug>(fern-action-enter)
endfunction

augroup FernGroup
  autocmd!
  autocmd FileType fern call FernInit()
augroup END

" https://stackoverflow.com/a/61382706/360593
" vim highlights $() in sh files as an error, because the original sh does not
" support it. POSIX does support it and pretty much everything I use is POSIX
" compliant, so just tell vim to be POSIX compliant too.
let g:is_posix = 1

"
" coc
"

if s:should_install_coc
  " Some servers have issues with backup files, see #649.
  set nobackup
  set nowritebackup

  " Always show the signcolumn, otherwise it would shift the text each time
  " diagnostics appear/become resolved.
  if has("patch-8.1.1564")
    " Recently vim can merge signcolumn and number column into one
    set signcolumn=number
  else
    set signcolumn=yes
  endif

  " Use tab for trigger completion with characters ahead and navigate.
  " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
  " other plugin before putting this into your config.
  inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
  inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

  function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
  endfunction

  " Use <c-space> to trigger completion.
  if has('nvim')
    inoremap <silent><expr> <c-space> coc#refresh()
  else
    inoremap <silent><expr> <c-@> coc#refresh()
  endif

  " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
  " position. Coc only does snippet and additional edit on confirm.
  " <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
  if exists('*complete_info')
    inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
  else
    inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
  endif

  " Use `[g` and `]g` to navigate diagnostics
  " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
  nmap <silent> [g <Plug>(coc-diagnostic-prev)
  nmap <silent> ]g <Plug>(coc-diagnostic-next)

  " GoTo code navigation.
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)

  " Use K to show documentation in preview window.
  nnoremap <silent> K :call <SID>show_documentation()<CR>

  function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
      execute 'h '.expand('<cword>')
    else
      call CocActionAsync('doHover')
    endif
  endfunction

  " Highlight the symbol and its references when holding the cursor.
  autocmd CursorHold * silent call CocActionAsync('highlight')

  " Symbol renaming.
  nmap <leader>rn <Plug>(coc-rename)

  " Formatting selected code.
  xmap <leader>f  <Plug>(coc-format-selected)
  nmap <leader>f  <Plug>(coc-format-selected)

  augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup end

  " Applying codeAction to the selected region.
  " Example: `<leader>aap` for current paragraph
  xmap <leader>a  <Plug>(coc-codeaction-selected)
  nmap <leader>a  <Plug>(coc-codeaction-selected)

  " Remap keys for applying codeAction to the current buffer.
  nmap <leader>ac  <Plug>(coc-codeaction)
  " Apply AutoFix to problem on the current line.
  nmap <leader>qf  <Plug>(coc-fix-current)

  " Map function and class text objects
  " NOTE: Requires 'textDocument.documentSymbol' support from the language server.
  xmap if <Plug>(coc-funcobj-i)
  omap if <Plug>(coc-funcobj-i)
  xmap af <Plug>(coc-funcobj-a)
  omap af <Plug>(coc-funcobj-a)
  xmap ic <Plug>(coc-classobj-i)
  omap ic <Plug>(coc-classobj-i)
  xmap ac <Plug>(coc-classobj-a)
  omap ac <Plug>(coc-classobj-a)

  " Use CTRL-S for selections ranges.
  " Requires 'textDocument/selectionRange' support of language server.
  nmap <silent> <C-s> <Plug>(coc-range-select)
  xmap <silent> <C-s> <Plug>(coc-range-select)

  " Add `:Format` command to format current buffer.
  command! -nargs=0 Format :call CocAction('format')

  " Add `:Fold` command to fold current buffer.
  command! -nargs=? Fold :call     CocAction('fold', <f-args>)

  " Add `:OR` command for organize imports of the current buffer.
  command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

  " Mappings for CoCList
  " Show all diagnostics.
  nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
  " Manage extensions.
  nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
  " Show commands.
  nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
  " Find symbol of current document.
  nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
  " Search workspace symbols.
  nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
  " Do default action for next item.
  nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
  " Do default action for previous item.
  nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
  " Resume latest coc list.
  nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
endif

"
" END coc
"

" Treesitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "ruby", "javascript", "typescript", "python", "bash", "toml", "json", "html", "yaml" },     -- one of "all", "language", or a list of languages
  highlight = {
    enable = true,              -- false will disable the whole extension
  },
}
EOF

set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()

" vim: nocursorline
