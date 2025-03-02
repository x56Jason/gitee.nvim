if exists("b:current_syntax")
  finish
endif

syn match GlanceCommitDiffAdd /.*/ contained
syn match GlanceCommitDiffDelete /.*/ contained

hi def GlanceCommitDiffAdd guifg=#000000 guibg=#859900
hi def GlanceCommitDiffDelete guifg=#ffffff guibg=#dc322f
hi def GlanceCommitHunkHeader guifg=#cccccc guibg=#404040
hi def GlanceCommitFilePath guifg=#7e9cd8

hi def GlanceCommitViewHeader guifg=#000000 guibg=#94bbd1
hi def GlanceCommitDesc guifg=#a6a69c guibg=#000000

hi def GlanceCommitHeaderField guifg=#dca561 guibg=#000000
hi def GlanceCommitSummary guifg=#dca561 guibg=#000000

sign define GlanceCommitHunkHeader linehl=GlanceCommitHunkHeader

sign define GlanceCommitDiffAdd linehl=GlanceCommitDiffAdd
sign define GlanceCommitDiffDelete linehl=GlanceCommitDiffDelete

sign define GlanceCommitViewHeader linehl=GlanceCommitViewHeader
sign define GlanceCommitDesc linehl=GlanceCommitDesc

sign define GlanceCommitHeaderField linehl=GlanceCommitHeaderField
sign define GlanceCommitSummary linehl=GlanceCommitSummary
