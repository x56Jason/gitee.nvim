if exists("b:current_syntax")
  finish
endif

"syn match Function /^[a-z0-9]\{12}\ze/

"hi def GlancePRListCommit guibg=#000000 guifg=#94bbd1
hi def GlancePRListCommit guibg=NONE guifg=#859900
hi def GlancePRListSubject guibg=NONE 
hi def GlancePRListCLAYes guibg=NONE guifg=#20c22e
hi def GlancePRListCLANo guibg=NONE guifg=#e82424
hi def GlancePRListLGTM guibg=NONE guifg=#20c22e
hi def GlancePRListCISuccess guibg=NONE guifg=#20c22e
hi def GlancePRListCIFail guibg=NONE guifg=#e82424
hi def GlancePRListSigKernel guibg=NONE guifg=#1dcaf9
hi def GlancePRListNeedSquash guibg=NONE guifg=#febc08
hi def GlancePRListAcked guibg=NONE guifg=#1dcaf9
hi def GlancePRListApproved guibg=NONE guifg=#1dbaae
hi def GlancePRListNewComer guibg=NONE guifg=#1083d6
hi def GlancePRListCommentHead guibg=NONE guifg=#94bbd1
hi def GlancePRListCompareList guibg=NONE guifg=#20c22c

