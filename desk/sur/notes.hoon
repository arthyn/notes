::  notes: shared notebook surface types (ACUR split)
::
|%
+$  role
  ?(%owner %editor %viewer)
::
+$  notebook
  $:  id=@ud
      title=@t
      created-by=ship
      created-at=@da
      updated-at=@da
  ==
::
+$  folder
  $:  id=@ud
      notebook-id=@ud
      name=@t
      parent-folder-id=(unit @ud)
      created-by=ship
      created-at=@da
      updated-at=@da
  ==
::
+$  note
  $:  id=@ud
      notebook-id=@ud
      folder-id=@ud
      title=@t
      slug=(unit @t)
      body-md=@t
      created-by=ship
      created-at=@da
      updated-by=ship
      updated-at=@da
      revision=@ud
  ==
::
+$  notebook-members  (map ship role)
::
+$  import-node
  $%  [%folder name=@t children=(list import-node)]
      [%note title=@t body-md=@t]
  ==
::
::  ACUR
+$  a-notes
  $%  [%create-notebook title=@t]
      [%rename-notebook notebook-id=@ud title=@t]
      [%join notebook-id=@ud]
      [%leave notebook-id=@ud]
      [%create-folder notebook-id=@ud parent-folder-id=(unit @ud) name=@t]
      [%rename-folder notebook-id=@ud folder-id=@ud name=@t]
      [%move-folder notebook-id=@ud folder-id=@ud new-parent-folder-id=@ud]
      [%delete-folder notebook-id=@ud folder-id=@ud recursive=?]
      [%create-note notebook-id=@ud folder-id=@ud title=@t body-md=@t]
      [%rename-note notebook-id=@ud note-id=@ud title=@t]
      [%move-note note-id=@ud notebook-id=@ud folder-id=@ud]
      [%delete-note note-id=@ud notebook-id=@ud]
      [%update-note note-id=@ud body-md=@t expected-revision=@ud]
      [%batch-import notebook-id=@ud folder-id=@ud notes=(list [title=@t body-md=@t])]
      $:  %batch-import-tree
          notebook-id=@ud
          parent-folder-id=@ud
          tree=(list import-node)
      ==
  ==
::
+$  c-notes
  $%  [%create-notebook title=@t actor=ship]
      [%rename-notebook notebook-id=@ud title=@t actor=ship]
      [%join notebook-id=@ud actor=ship]
      [%leave notebook-id=@ud actor=ship]
      [%create-folder notebook-id=@ud parent-folder-id=(unit @ud) name=@t actor=ship]
      [%rename-folder notebook-id=@ud folder-id=@ud name=@t actor=ship]
      [%move-folder notebook-id=@ud folder-id=@ud new-parent-folder-id=@ud actor=ship]
      [%delete-folder notebook-id=@ud folder-id=@ud recursive=? actor=ship]
      [%create-note notebook-id=@ud folder-id=@ud title=@t body-md=@t actor=ship]
      [%rename-note notebook-id=@ud note-id=@ud title=@t actor=ship]
      [%move-note note-id=@ud notebook-id=@ud folder-id=@ud actor=ship]
      [%delete-note note-id=@ud notebook-id=@ud actor=ship]
      [%update-note note-id=@ud body-md=@t expected-revision=@ud actor=ship]
      [%batch-import notebook-id=@ud folder-id=@ud notes=(list [title=@t body-md=@t]) actor=ship]
      $:  %batch-import-tree
          notebook-id=@ud
          parent-folder-id=@ud
          tree=(list import-node)
          actor=ship
      ==
  ==
::
+$  u-notes
  $%  [%notebook-created notebook-id=@ud actor=ship]
      [%notebook-renamed notebook-id=@ud actor=ship]
      [%member-joined notebook-id=@ud who=ship actor=ship]
      [%member-left notebook-id=@ud who=ship actor=ship]
      [%folder-created folder-id=@ud notebook-id=@ud actor=ship]
      [%folder-renamed folder-id=@ud notebook-id=@ud actor=ship]
      [%folder-moved folder-id=@ud notebook-id=@ud actor=ship]
      [%folder-deleted folder-id=@ud notebook-id=@ud actor=ship]
      [%note-created note-id=@ud notebook-id=@ud actor=ship]
      [%note-renamed note-id=@ud notebook-id=@ud actor=ship]
      [%note-moved note-id=@ud notebook-id=@ud folder-id=@ud actor=ship]
      [%note-deleted note-id=@ud notebook-id=@ud actor=ship]
      [%note-updated note-id=@ud notebook-id=@ud revision=@ud actor=ship]
  ==
::
+$  r-notes
  $%  [%update seq=@ud update=u-notes]
      [%snapshot notebook-id=@ud notebook=(unit notebook) folders=(list folder) notes=(list note)]
  ==
::
::  compatibility aliases (transition)
+$  action  a-notes
+$  event   u-notes
::
+$  state-0
  [%0 notebooks=(map @ud notebook) folders=(map @ud folder) notes=(map @ud note) members=(map @ud notebook-members) next-id=@ud updates=(map @ud u-notes) next-update-id=@ud]
::
+$  state  state-0
--
