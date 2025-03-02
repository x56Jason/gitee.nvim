if exists("b:current_syntax")
  finish
endif

"syn match Function /^[a-z0-9]\{12}\ze/

"hi def GlanceLogCommit guifg=#94bbd1
hi def GlanceLogCommit guifg=#859900
hi def GlanceLogRemote guifg=#dc322f
hi def GlanceLogSubject guibg=NONE 
hi def GlanceLogHeader guifg=#94bbd1
hi def GlanceLogHeaderField guifg=#dca561
"hi def GlanceLogHeaderHead guifg=#e82424
hi def GlanceLogHeaderHead guifg=#dc322f
hi def GlanceLogHeaderBase guifg=#008000
hi def GlanceLogCLAYes guifg=#20c22e
hi def GlanceLogLGTM guifg=#20c22e
hi def GlanceLogCISuccess guifg=#20c22e
hi def GlanceLogSigKernel guifg=#1dcaf9
hi def GlanceLogNeedSquash guifg=#febc08
hi def GlanceLogAcked guifg=#1dcaf9
hi def GlanceLogApproved guifg=#1dbaae
hi def GlanceLogNewComer guifg=#1083d6
hi def GlanceLogCommentHead guifg=#94bbd1
hi def GlanceLogCompareList guifg=#20c22c
hi def GlanceLogSelect guifg=#e82424

sign define GlanceLogHeader linehl=GlanceLogHeader
sign define GlanceLogHeaderField linehl=GlanceLogHeaderField
sign define GlanceLogHeaderHead linehl=GlanceLogHeaderHead
sign define GlanceLogHeaderBase linehl=GlanceLogHeaderBase
sign define GlanceLogCommentHead linehl=GlanceLogCommentHead

