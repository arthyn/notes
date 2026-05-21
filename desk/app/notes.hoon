::  notes: shared notebook Gall agent (dual-mode host/subscriber)
::
/-  n=notes
/+  default-agent, dbug, verb, notes-json
/=  ui            /lib/notes-ui
/=  share-page    /lib/notes-share
/=  openapi-spec  /lib/notes-openapi
::
|%
+$  card  card:agent:gall
+$  current-state  state-11:n
--
::
=|  current-state
=*  state  -
::
%-  agent:dbug
%+  verb  |
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    cor   ~(. +> [bowl ~])
::
++  on-init
  ^-  (quip card _this)
  =^  cards  state
    abet:init:cor
  [cards this]
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =^  cards  state
    abet:(load:cor old)
  [cards this]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state
    abet:(poke:cor mark vase)
  [cards this]
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  =^  cards  state
    abet:(watch:cor `(pole knot)`path)
  [cards this]
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  (peek:cor `(pole knot)`path)
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  =^  cards  state
    abet:(agent:cor `(pole knot)`wire sign)
  [cards this]
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  =^  cards  state
    abet:(arvo:cor wire sign-arvo)
  [cards this]
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::  helper core
::
|_  [=bowl:gall cards=(list card)]
++  dummy  'serve-openapi-json'
++  abet  [(flop cards) state]
++  cor   .
++  emit  |=(=card cor(cards [card cards]))
++  emil  |=(caz=(list card) cor(cards (welp (flop caz) cards)))
++  give  |=(=gift:agent:gall (emit %give gift))
::
++  init
  ^+  cor
  %-  emil
  :~  [%pass /eyre/notes %arvo %e %connect [~ /notes] %notes]
      [%pass /cleanup/requests %arvo %b %wait (add now.bowl ~m5)]
  ==
::
::  +load: migrate old state to current state-10 via linear per-step chain.
::  Pattern: |^ kelt with =? chain + per-step arms (tloncorp/homestead style).
::
++  load
  |^  |=  =vase
  ^+  cor
  =+  !<(old=any-state vase)
  =?  old  ?=(%1 -.old)  (state-1-to-2 old)
  =?  old  ?=(%2 -.old)  (state-2-to-3 old)
  =?  old  ?=(%3 -.old)  (state-3-to-4 old)
  =?  old  ?=(%4 -.old)  (state-4-to-5 old)
  =?  old  ?=(%5 -.old)  (state-5-to-6 old)
  =?  old  ?=(%6 -.old)  (state-6-to-7 old)
  =?  old  ?=(%7 -.old)  (state-7-to-8 old)
  =?  old  ?=(%8 -.old)  (state-8-to-9 old)
  =?  old  ?=(%9 -.old)  (state-9-to-10 old)
  =?  old  ?=(%10 -.old)  (state-10-to-11 old)
  ?>  ?=(%11 -.old)
  =.  state  old
  ::  start request cleanup timer (idempotent: stacking timers is fine,
  ::  each cleanup pass is a no-op on an empty/clean requests map)
  %-  emit
  [%pass /cleanup/requests %arvo %b %wait (add now.bowl ~m5)]
  ::
  +$  any-state
    $%  state-11:n
        state-10:n
        state-9:n
        state-8:n
        state-7:n
        state-6:n
        state-5:n
        state-4:n
        state-3:n
        state-2:n
        state-1:n
    ==
  ::
  ++  state-1-to-2
    ~>  %spin.['state-1-to-2']
    |=  s=state-1:n
    ^-  state-2:n
    [%2 books.s next-id.s ~]
  ::
  ++  state-2-to-3
    ~>  %spin.['state-2-to-3']
    |=  s=state-2:n
    ^-  state-3:n
    [%3 books.s next-id.s ~]
  ::
  ++  state-3-to-4
    ~>  %spin.['state-3-to-4']
    |=  s=state-3:n
    ^-  state-4:n
    [%4 books.s next-id.s published.s ~]
  ::
  ++  state-4-to-5
    ~>  %spin.['state-4-to-5']
    |=  s=state-4:n
    ^-  state-5:n
    [%5 books.s next-id.s published.s visibilities.s ~]
  ::
  ++  state-5-to-6
    ~>  %spin.['state-5-to-6']
    |=  s=state-5:n
    ^-  state-6:n
    =/  new-invites=(map flag-v9:n invite-info:n)
      %-  ~(run by invites.s)
      |=  ii=invite-info-5:n
      ^-  invite-info:n
      [from.ii sent-at.ii '']
    [%6 books.s next-id.s published.s visibilities.s new-invites]
  ::
  ++  state-6-to-7
    ~>  %spin.['state-6-to-7']
    |=  s=state-6:n
    ^-  state-7:n
    [%7 books.s next-id.s published.s visibilities.s invites.s ~]
  ::
  ++  state-7-to-8
    ~>  %spin.['state-7-to-8']
    |=  s=state-7:n
    ^-  state-8:n
    =/  new-books=(map flag-v9:n [=net:n =notebook-state-v8:n])
      %-  ~(run by books.s)
      |=  [net=net-v0:n old-nbs=notebook-state-v0:n]
      =/  =notebook:n
        :*  id.notebook.old-nbs  title.notebook.old-nbs
            created-by.notebook.old-nbs  created-at.notebook.old-nbs
            updated-at.notebook.old-nbs  created-by.notebook.old-nbs
        ==
      =/  new-folders=(map @ud folder:n)
        %-  ~(run by folders.old-nbs)
        |=  fld=folder-v0:n
        :*  id.fld  notebook-id.fld  name.fld  parent-folder-id.fld
            created-by.fld  created-at.fld  updated-at.fld  created-by.fld
        ==
      =/  new-net=net:n
        ?-  -.net
          %pub  [%pub *log:n]
          %sub  [%sub time.net init.net]
        ==
      [new-net [notebook notebook-members.old-nbs new-folders notes.old-nbs]]
    [%8 new-books next-id.s published.s visibilities.s invites.s history.s]
  ::
  ++  state-8-to-9
    ~>  %spin.['state-8-to-9']
    |=  s=state-8:n
    ^-  state-9:n
    =/  new-books=(map flag-v9:n [=net:n =notebook-state:n])
      %-  ~(urn by books.s)
      |=  [f=flag-v9:n [=net:n old-nbs=notebook-state-v8:n]]
      =/  nb-hist=(map @ud (list note-revision:n))
        %-  malt
        %+  murn  ~(tap by history.s)
        |=  [[kf=flag-v9:n nid=@ud] v=(list note-revision:n)]
        ?.  =(kf f)  ~
        `[nid v]
      =/  new-nbs=notebook-state:n
        :*  notebook.old-nbs
            notebook-members.old-nbs
            (fall (~(get by visibilities.s) f) %private)
            folders.old-nbs
            notes.old-nbs
            nb-hist
        ==
      [net new-nbs]
    [%9 new-books next-id.s published.s invites.s]
  ::
  ++  state-9-to-10
    ~>  %spin.['state-9-to-10']
    |=  s=state-9:n
    ^-  state-10:n
    =/  xlat=(map flag-v9:n flag:n)
      %-  malt
      %+  turn  ~(tap by books.s)
      |=  [f=flag-v9:n [* =notebook-state:n]]
      =/  new-name=@tas  (slugify [title id]:notebook.notebook-state)
      [f [ship.f new-name]]
    =/  new-books=(map flag:n [=net:n =notebook-state:n])
      %-  malt
      %+  turn  ~(tap by books.s)
      |=  [f=flag-v9:n entry=[=net:n =notebook-state:n]]
      =/  =flag:n  (~(got by xlat) f)
      [flag entry]
    =/  new-pub=(map [=flag:n note-id=@ud] @t)
      %-  malt
      %+  turn  ~(tap by published.s)
      |=  [[f=flag-v9:n nid=@ud] html=@t]
      =/  =flag:n  (fall (~(get by xlat) f) [ship.f `@tas`name.f])
      [[flag nid] html]
    =/  new-invites=(map flag:n invite-info:n)
      %-  malt
      %+  turn  ~(tap by invites.s)
      |=  [f=flag-v9:n info=invite-info:n]
      =/  =flag:n  (fall (~(get by xlat) f) [ship.f `@tas`name.f])
      [flag info]
    [%10 new-books next-id.s new-pub new-invites]
  ::
  ++  state-10-to-11
    ~>  %spin.['state-10-to-11']
    |=  s=state-10:n
    ^-  state-11:n
    [%11 books.s next-id.s published.s invites.s ~]
  --
::
++  poke
  |=  [=mark =vase]
  ^+  cor
  |^
  ?+  mark  ~|(bad-mark+mark !!)
      %handle-http-request
    (serve-http !<([eyre-id=@ta =inbound-request:eyre] vase))
  ::
      %notes-action
    ::  Actions are local UI requests — they originate from our own ship.
    ::  Cross-ship messages (host → invitee notify-invite, subscriber →
    ::  host commands) flow via %notes-command instead.
    ?>  =(our.bowl src.bowl)
    =+  !<(act=action:n vase)
    ::  switchable top-level cases first; %notebook (notebook-scoped) is meaty
    ?.  ?=(%notebook -.act)
      ?-  -.act
        %create-notebook  se-abet:(se-create-notebook:(se-init:se-core act) act)
        %join             (join-remote flag.act)
        %leave            (leave-remote flag.act)
        %accept-invite    (handle-accept-invite flag.act)
        %decline-invite   (handle-decline-invite flag.act)
      ==
    ::  notebook-scoped: [%notebook =flag =a-notebook]
    =/  =flag:n  flag.act
    ?+    -.a-notebook.act
        ::  default: send command to host (which might be us — Gall loops it back)
      no-abet:(no-action:(no-abed:no-core flag) act)
    ::
        %invite
      ::  owner sends invite to a ship — handled locally
      (handle-send-invite flag who.a-notebook.act)
    ::
        %note
      ::  %publish / %unpublish are local-only; everything else routes via no-action
      =*  n-act  a-note.a-notebook.act
      ?+    -.n-act
          ::  default: send command to host
        no-abet:(no-action:(no-abed:no-core flag) act)
      ::
          %publish
        no-abet:(no-publish:(no-abed:no-core flag) id.a-notebook.act html.n-act)
      ::
          %unpublish
        no-abet:(no-unpublish:(no-abed:no-core flag) id.a-notebook.act)
      ==
    ==
  ::
      %notes-command
    =+  !<(cmd=command:n vase)
    ?-    -.cmd
        %notify-invite
      ::  Cross-ship invite delivery — src.bowl validation lives in
      ::  handle-notify-invite (must equal ship.flag, the inviting host).
      (handle-notify-invite flag.cmd title.cmd src.bowl)
    ::
        %notebook
      =*  flag  flag.cmd
      ::  member-join/-leave: any ship can request membership change on
      ::  a notebook we host; se-member-join/-leave enforces visibility
      ::  + role logic. All other commands assume the sender is already
      ::  a member; se-poke arms re-check via se-can-edit/se-is-owner.
      ?>  =(ship.flag our.bowl)
      ?>  (~(has by books) flag)
      se-abet:(se-poke:(se-abed:se-core flag) [flag c-notebook.cmd])
    ==
  ::
      %notes-action-1
    ::  v1 action — carries request-id. Local UI / HTTP API origin.
    ?>  =(our.bowl src.bowl)
    =+  !<(act=action:v1:n vase)
    =/  rid  request-id.act
    =/  a-act  a-notes.act
    =.  cor  (register-request rid ~)
    ?.  ?=(%notebook -.a-act)
      ::  top-level actions: handle locally, finalize %no-change synchronously.
      ::  (Future: %ok with snapshot for %create-notebook etc.)
      =.  cor
        ?-  -.a-act
          %create-notebook  se-abet:(se-create-notebook:(se-init:se-core a-act) a-act)
          %join             (join-remote flag.a-act)
          %leave            (leave-remote flag.a-act)
          %accept-invite    (handle-accept-invite flag.a-act)
          %decline-invite   (handle-decline-invite flag.a-act)
        ==
      (finalize-request rid [%no-change ~])
    ::  notebook-scoped — route through no-action-v1 for cross-ship lifecycle.
    =/  =flag:n  flag.a-act
    ?+    -.a-notebook.a-act
        no-abet:(no-action-v1:(no-abed:no-core flag) rid a-act)
    ::
        %invite
      =.  cor  (handle-send-invite flag who.a-notebook.a-act)
      (finalize-request rid [%no-change ~])
    ::
        %note
      =*  n-act  a-note.a-notebook.a-act
      ?+    -.n-act
          no-abet:(no-action-v1:(no-abed:no-core flag) rid a-act)
      ::
          %publish
        =.  cor  no-abet:(no-publish:(no-abed:no-core flag) id.a-notebook.a-act html.n-act)
        (finalize-request rid [%no-change ~])
      ::
          %unpublish
        =.  cor  no-abet:(no-unpublish:(no-abed:no-core flag) id.a-notebook.a-act)
        (finalize-request rid [%no-change ~])
      ==
    ==
  ::
      %notes-command-1
    ::  v1 cross-ship command — wraps c-notes with a request-id.
    =+  !<(cmd1=command:v1:n vase)
    =/  rid  request-id.cmd1
    =/  cmd  c-notes.cmd1
    ?-    -.cmd
        %notify-invite
      (handle-notify-invite flag.cmd title.cmd src.bowl)
    ::
        %notebook
      =*  flag  flag.cmd
      ?>  =(ship.flag our.bowl)
      ?>  (~(has by books) flag)
      se-abet:(se-poke-v1:(se-abed:se-core flag) rid [flag c-notebook.cmd])
    ==
  ==
  ::
  ::  +join-remote: initiate joining a notebook on a remote ship
  ++  join-remote
    |=  =flag:n
    ^+  cor
    ?<  =(our.bowl ship.flag)
    ?<  (~(has by books) flag)
    =/  placeholder-net=net:n  [%sub *@da |]
    =/  =notebook:n
      [0 '' ship.flag *@da *@da ship.flag]
    =/  placeholder-nb-state=notebook-state:n
      [notebook ~ %private ~ ~ ~]
    =.  books
      (~(put by books) flag [placeholder-net placeholder-nb-state])
    ::  send %member-join command to host (wrapped in c-notes %notebook arm)
    %-  emit
    :+  %pass
      /notes/join/(scot %p ship.flag)/[name.flag]
    [%agent [ship.flag %notes] %poke notes-command+!>(`command:n`[%notebook flag [%member-join ~]])]
  ::
  ::  +leave-remote: leave a notebook on a remote ship.
  ::  Tells the host to drop us from members BEFORE cancelling the watch
  ::  so the host's `members.notebook-state` reflects reality.
  ++  leave-remote
    |=  =flag:n
    ^+  cor
    ?>  (~(has by books) flag)
    =.  cor
      %-  emit
      :+  %pass
        /notes/leave/(scot %p ship.flag)/[name.flag]
      [%agent [ship.flag %notes] %poke notes-command+!>(`command:n`[%notebook flag [%member-leave ~]])]
    no-abet:no-leave:(no-abed:no-core flag)
  ::
  ::  +handle-send-invite: owner-only, fired locally. Pre-add the target ship
  ::  to the notebook's member list and notify their %notes agent.
  ++  handle-send-invite
    |=  [=flag:n who=ship]
    ^+  cor
    ?>  =(ship.flag our.bowl)
    =/  entry=[* =notebook-state:n]
      (~(got by books) flag)
    ::  pre-add via se-core (also enforces ownership)
    =.  cor
      =/  cmd=c-cmd:n  [flag [%invite who]]
      se-abet:(se-poke:(se-abed:se-core flag) cmd)
    ::  Poke the invitee's notes agent with %notify-invite as a c-notes
    ::  command — actions are local-only (src must equal our), so cross-
    ::  ship invite delivery flows through the command surface. The arm
    ::  carries the notebook title so the inbox can render it pre-join.
    %-  emit
    :+  %pass
      /notes/invite/(scot %p who)/(scot %p ship.flag)/[name.flag]
    [%agent [who %notes] %poke notes-command+!>(`command:n`[%notify-invite flag title.notebook.notebook-state.entry])]
  ::
  ::  +handle-notify-invite: called when a remote host pokes us with
  ::  [%notify-invite flag title]. The sender must be the notebook host.
  ++  handle-notify-invite
    |=  [=flag:n title=@t from=ship]
    ^+  cor
    ?<  =(from our.bowl)
    ?>  =(from ship.flag)
    ?:  (~(has by books) flag)  cor
    ?:  (~(has by invites) flag)  cor
    =/  info=invite-info:n  [from now.bowl title]
    =.  invites  (~(put by invites) flag info)
    (give-inbox-received flag from now.bowl title)
  ::
  ::  +handle-accept-invite: user accepted a pending invite
  ++  handle-accept-invite
    |=  =flag:n
    ^+  cor
    ?>  =(src.bowl our.bowl)
    =.  invites  (~(del by invites) flag)
    =.  cor  (give-inbox-removed flag)
    ?:  (~(has by books) flag)  cor
    (join-remote flag)
  ::
  ::  +handle-decline-invite: user declined a pending invite
  ++  handle-decline-invite
    |=  =flag:n
    ^+  cor
    ?>  =(src.bowl our.bowl)
    ?.  (~(has by invites) flag)  cor
    =.  invites  (~(del by invites) flag)
    (give-inbox-removed flag)
  --
::
::  +serve-http: dispatch an HTTP request to the right responder.
::  Order: v1 API → PWA static assets → published note → share redirect → UI fallback.
++  serve-http
  |=  [eyre-id=@ta =inbound-request:eyre]
  ^+  cor
  =/  url-tape=tape  (trip url.request.inbound-request)
  =/  url-path=tape  (strip-query url-tape)
  =/  method=@tas  method.request.inbound-request
  ::  openapi spec — served public so an MCP proxy can fetch it without
  ::  having to invent an auth scheme. The spec is metadata, not a side
  ::  channel into agent state. JSON only because %mcp-proxy parses
  ::  cached specs with de:json:html and doesn't accept YAML.
  ?:  =("/notes/openapi.json" url-path)
    =/  body=octs  (as-octs:mimes:html json:openapi-spec)
    %-  emil
    :~  [%give %fact [/http-response/[eyre-id]]~ %http-response-header !>(`response-header:http`[200 ~[['content-type' 'application/json']]])]
        [%give %fact [/http-response/[eyre-id]]~ %http-response-data !>(`body)]
        [%give %kick [/http-response/[eyre-id]]~ ~]
    ==
  ::  v1 HTTP API: POST /notes/~/v1, GET /notes/~/v1/request/<uv>
  ?:  =("/notes/~/v1" url-path)
    ?:  =(%'POST' method)  (handle-v1-post eyre-id inbound-request)
    (http-error eyre-id 405 'method not allowed')
  ?:  =("/notes/~/v1/request/" (scag 20 url-path))
    ?:  =(%'GET' method)  (handle-v1-get-request eyre-id (slag 20 url-path))
    (http-error eyre-id 405 'method not allowed')
  ::  PWA-related static assets: manifest, service worker, icons.
  ::  Each returns [body content-type] or ~. Served scoped under
  ::  /notes/ so the SW can control the app's URL space.
  =/  asset=(unit [body=@t ct=@t])
    ?:  =("/notes/manifest.json" url-path)
      `[manifest:ui 'application/manifest+json']
    ?:  =("/notes/sw.js" url-path)
      ::  text/javascript is required by some browsers for SW registration.
      `[service-worker:ui 'text/javascript']
    ?:  =("/notes/icon.svg" url-path)
      `[icon-svg:ui 'image/svg+xml']
    ?:  =("/notes/favicon.svg" url-path)
      `[favicon-svg:ui 'image/svg+xml']
    ~
  ::  /notes/pub/~ship/name/{note-id} → serve archived published HTML
  =/  pub-html=(unit @t)
    ?.  =("/notes/pub/" (scag 11 url-tape))  ~
    =/  path-only=tape  (strip-query (slag 11 url-tape))
    =/  pax=path  (stab (crip (weld "/" path-only)))
    ?.  ?=([@ @ @ ~] pax)  ~
    ?~  ship-u=(slaw %p i.pax)  ~
    ?~  nid-u=(slaw %ud i.t.t.pax)  ~
    ?:  =(0 u.nid-u)  ~
    =/  =flag:n  [u.ship-u `@tas`i.t.pax]
    (~(get by published) [flag u.nid-u])
  ::  /notes/share/~ship/name → serve the share-redirect page
  =/  share-html=(unit @t)
    ?.  =("/notes/share/" (scag 13 url-tape))  ~
    =/  path-only=tape  (strip-query (slag 13 url-tape))
    =/  pax=path  (stab (crip (weld "/" path-only)))
    ?.  ?=([@ @ ~] pax)  ~
    ?~  (slaw %p i.pax)  ~
    `share-page
  =/  body=@t
    ?^  asset       body.u.asset
    ?^  pub-html    u.pub-html
    ?^  share-html  u.share-html
    index:ui
  =/  ct=@t
    ?^  asset  ct.u.asset
    'text/html'
  =/  data=octs  [(met 3 body) body]
  =/  =response-header:http  [200 ~[['content-type' ct]]]
  %-  emil
  :~  [%give %fact [/http-response/[eyre-id]]~ %http-response-header !>(response-header)]
      [%give %fact [/http-response/[eyre-id]]~ %http-response-data !>(`data)]
      [%give %kick [/http-response/[eyre-id]]~ ~]
  ==
::
::  +handle-v1-post: parse a v1 action from the POST body, register the
::  request with eyre-id as http-id (so the HTTP request is held open until
::  finalize-request emits the response), then dispatch via the normal
::  %notes-action-1 poke routing.
++  handle-v1-post
  |=  [eyre-id=@ta =inbound-request:eyre]
  ^+  cor
  ?~  body.request.inbound-request
    (http-error eyre-id 400 'missing body')
  =/  body-cord=@t  q.u.body.request.inbound-request
  =/  jon=(unit json)  (de:json:html body-cord)
  ?~  jon  (http-error eyre-id 400 'invalid json')
  =/  =action:v1:n  (action:v1:dejs:notes-json u.jon)
  =/  rid  request-id.action
  ::  register with eyre-id so the in-flight HTTP request is tracked
  =.  requests
    %+  ~(put by requests)  rid
    [rid `eyre-id %sending ~ ~ |]
  ::  dispatch through the same code path as %notes-action-1 poke
  (poke %notes-action-1 !>(action))
::
::  +handle-v1-get-request: respond with the current state of a request.
::  Path remainder is the @uv id. If the request has a terminal result,
::  mark fetched=& so cleanup can evict it sooner.
++  handle-v1-get-request
  |=  [eyre-id=@ta path-rest=tape]
  ^+  cor
  =/  pax=path  (stab (crip (weld "/" path-rest)))
  ?.  ?=([@ ~] pax)
    (http-error eyre-id 404 'bad path')
  =/  rid=request-id:v1:n  (slav %uv i.pax)
  ?~  req=(~(get by requests) rid)
    (http-error eyre-id 404 'request not found')
  =/  body=response-body:v1:n
    ?~  result.u.req  [%pending poke-status.u.req]
    u.result.u.req
  =.  requests
    (~(put by requests) rid u.req(fetched &))
  (give-http-response eyre-id [rid body])
::
++  watch
  |=  =(pole knot)
  ^+  cor
  ?+  pole  ~|(bad-watch-path+pole !!)
      [%http-response *]
    cor
  ::
      [%v0 %notes ship=@ name=@ %updates ~]
    ::  remote subscriber watching our hosted notebook's update stream
    =/  =flag:n  [(slav %p ship.pole) `@tas`name.pole]
    ?>  =(our.bowl ship.flag)
    se-abet:se-watch:(se-abed:se-core flag)
  ::
      [%v0 %notes ship=@ name=@ %stream ~]
    ::  local UI subscription for any notebook (pub or sub)
    =/  =flag:n  [(slav %p ship.pole) `@tas`name.pole]
    no-abet:no-watch:(no-abed:no-core flag)
  ::
      [%v0 %inbox %stream ~]
    ?>  =(src.bowl our.bowl)
    cor
  ::
      [%v1 %notes ship=@ name=@ %request requester=@ id=@ ~]
    ::  host-side per-request path. Other ships subscribe here while
    ::  awaiting their response-update. Path includes requester ship
    ::  so the host can scope facts and reject impersonation.
    =/  =flag:n  [(slav %p ship.pole) `@tas`name.pole]
    ?>  =(our.bowl ship.flag)
    =/  req-ship=ship  (slav %p requester.pole)
    ?>  =(src.bowl req-ship)
    cor
  ::
      [%v1 %request id=@ ~]
    ::  local SSE per-request stream. If we already hold a terminal
    ::  result, send it now so the subscriber doesn't need to poll GET.
    ?>  =(src.bowl our.bowl)
    =/  rid=request-id:v1:n  (slav %uv id.pole)
    ?~  req=(~(get by requests) rid)  cor
    ?~  result.u.req  cor
    %-  give
    :+  %fact  ~
    notes-response-1+!>(`response:v1:n`[rid u.result.u.req])
  ==
::
++  peek
  |=  =(pole knot)
  ^-  (unit (unit cage))
  ?+  pole  ~
    ::  /x/ui — serve the frontend
      [%x %ui ~]
    ``html+!>(index:ui)
    ::  /x/v0/notebooks — list all notebooks (cross-cutting, no flag)
      [%x %v0 %notebooks ~]
    =/  summaries=(list notebook-summary:n)
      %+  murn  ~(tap by books)
      |=  [=flag:n [* =notebook-state:n]]
      ?.  (can-view-flag flag src.bowl)  ~
      `[flag [notebook visibility]:notebook-state]
    ``notes-notebooks+!>(summaries)
    ::  /x/v0/published — list of {host, flagName, noteId} for each published note
      [%x %v0 %published ~]
    =/  pub-records=(list published-record:n)
      %+  turn  ~(tap by published)
      |=  [[=flag:n note-id=@ud] *]
      [flag note-id]
    ``notes-published+!>(pub-records)
    ::  /x/v0/invites — pending invites we've received
      [%x %v0 %invites ~]
    =/  inv-records=(list invite-record:n)
      %+  turn  ~(tap by invites)
      |=  [=flag:n info=invite-info:n]
      [flag info]
    ``notes-invites+!>(inv-records)
    ::  /x/debug/dummy — current ++dummy value for tooling readiness checks
      [%x %debug %dummy ~]
    ``json+!>(s+dummy)
    ::  /x/v0/<kind>/<ship>/<name>[/<rest>] — delegate to no-peek
      [%x %v0 kind=@ ship=@ name=@ rest=*]
    =/  =flag:n  [(slav %p ship.pole) `@tas`name.pole]
    ?~  (~(get by books) flag)  ~
    (no-peek:(no-abed:no-core flag) kind.pole rest.pole)
  ==
::
++  agent
  |=  [=(pole knot) =sign:agent:gall]
  ^+  cor
  ?+  pole  ~|(bad-agent-wire+pole !!)
      [%notes %sub ship=@ name=@ ~]
    =/  =flag:n
      [(slav %p ship.pole) `@tas`name.pole]
    ?.  (~(has by books) flag)
      cor
    no-abet:(no-agent:(no-abed:no-core flag) sign)
  ::
      [%notes %join ship=@ name=@ ~]
    =/  =flag:n
      [(slav %p ship.pole) `@tas`name.pole]
    ?+  -.sign  cor
        %poke-ack
      ?~  p.sign
        ::  poke succeeded — host has added us, now subscribe
        no-abet:no-start-watch:(no-abed:no-core flag)
      ::  poke failed — remove placeholder from books
      =.  books  (~(del by books) flag)
      cor
    ==
  ::
      [%notes %invite who=@ ship=@ name=@ ~]
    ?+  -.sign  cor
        %poke-ack  cor
    ==
  ::
      [%notes %leave ship=@ name=@ ~]
    ::  Best-effort %member-leave to host on +leave-remote. We don't act
    ::  on the ack — the local entry is already gone either way.
    ?+  -.sign  cor
        %poke-ack  cor
    ==
  ::
      [%notes %req ship=@ name=@ id=@ %watch ~]
    ::  v1 per-request watch wire. Flag embedded in the wire so we can
    ::  route back into the right no-core context.
    =/  =flag:n  [(slav %p ship.pole) `@tas`name.pole]
    ?.  (~(has by books) flag)  cor
    =/  rid=request-id:v1:n  (slav %uv id.pole)
    no-abet:(no-agent-req-watch:(no-abed:no-core flag) rid sign)
  ::
      [%notes %req ship=@ name=@ id=@ %poke ~]
    =/  =flag:n  [(slav %p ship.pole) `@tas`name.pole]
    ?.  (~(has by books) flag)  cor
    =/  rid=request-id:v1:n  (slav %uv id.pole)
    no-abet:(no-agent-req-poke:(no-abed:no-core flag) rid sign)
  ==
::
++  arvo
  |=  [=wire =sign-arvo]
  ^+  cor
  ?:  ?=([%eyre %bound *] sign-arvo)  cor
  ?:  ?=([%behn %wake *] sign-arvo)
    =/  pole  ;;((pole knot) wire)
    ?+  pole  ~|(bad-arvo-wire+wire !!)
        [%cleanup %requests ~]
      ::  reschedule and run the cleanup pass. timer behaves the same
      ::  whether the requests map is empty or populated.
      =.  requests  (cleanup-requests now.bowl)
      %-  emit
      [%pass /cleanup/requests %arvo %b %wait (add now.bowl ~m5)]
    ::
        [%notes %rewatch ship=@ name=@ ~]
      =/  =flag:n  [(slav %p ship.pole) `@tas`name.pole]
      ?.  (~(has by books) flag)  cor
      =/  entry=[=net:n *]  (~(got by books) flag)
      ?.  ?=(%sub -.net.entry)  cor
      no-abet:no-start-watch:(no-abed:no-core flag)
    ::
        [%notes %req ship=@ name=@ id=@ %wake ~]
      ::  v1 per-request timeout — deliver %pending to the held HTTP
      ::  request (if any) and keep the request entry around for the
      ::  late-arriving response on the SSE path.
      =/  rid=request-id:v1:n  (slav %uv id.pole)
      (finalize-pending rid)
    ==
  ~|(bad-arvo-sign+wire !!)
::
::  ====  utility arms  ====
::
::  +slugify: convert a title cord + numeric suffix into a valid @tas term.
::  Algorithm:
::  1. Lowercase all chars; map non-[a-z0-9] to '-'
::  2. Collapse consecutive '-' into one
::  3. Trim leading and trailing '-'
::  4. Cap at 32 chars
::  5. Default to "note" if empty
::  6. Prefix "n-" if first char is a digit
::  7. Append "-{suffix}" (strip dots from scot %ud output)
++  slugify
  |=  [t=@t suffix=@ud]
  ^-  @tas
  =/  chars=tape  (trip t)
  ::  step 1: map each char to lowercase letter, digit, or '-'
  =/  mapped=tape
    %+  turn  chars
    |=  c=@t
    ^-  @t
    ?:  &((gte c 'a') (lte c 'z'))  c
    ?:  &((gte c 'A') (lte c 'Z'))  (add c 32)
    ?:  &((gte c '0') (lte c '9'))  c
    '-'
  ::  step 2: collapse consecutive '-' into one
  =/  collapsed=tape
    %-  flop
    =|  acc=tape
    |-  ^+  acc
    ?~  mapped  acc
    ?:  &(=('-' i.mapped) ?=(^ acc) =('-' i.acc))
      $(mapped t.mapped)
    $(mapped t.mapped, acc [i.mapped acc])
  ::  step 3: trim leading '-'
  =/  ltrimmed=tape
    |-  ^-  tape
    ?~  collapsed  ~
    ?:  =('-' i.collapsed)
      $(collapsed t.collapsed)
    collapsed
  ::  step 3b: trim trailing '-'
  =/  trimmed=tape
    =/  rev=tape  (flop ltrimmed)
    =/  rtrimmed=tape
      |-  ^-  tape
      ?~  rev  ~
      ?:  =('-' i.rev)
        $(rev t.rev)
      rev
    (flop rtrimmed)
  ::  step 4: cap at 32 chars
  =/  capped=tape  (scag 32 trimmed)
  ::  step 5: default to "note" if empty
  =/  base=tape  ?~(capped "note" capped)
  ::  step 6: prefix "n-" if first char is a digit
  =/  prefixed=tape
    ?.  &(?=(^ base) (gte i.base '0') (lte i.base '9'))
      base
    (weld "n-" base)
  ::  step 7: build suffix string (strip dots from scot %ud)
  =/  raw-suf=tape  (trip (scot %ud suffix))
  =/  suf-tape=tape
    %+  skim  raw-suf
    |=(c=@t !=(c '.'))
  =/  slug=tape  (weld (weld prefixed "-") suf-tape)
  `@tas`(crip slug)
::
::  +a-notebook-to-c-notebook: convert a-notebook to c-notebook (same shape except %restore)
::  %restore is rewritten to %note [id %update] with the archived body
++  a-notebook-to-c-notebook
  |=  nb-act=a-notebook:n
  ^-  c-notebook:n
  ::  a-notebook and c-notebook have identical shapes (c-notebook adds
  ::  %member-join/%member-leave which only arrive via %notes-command, never
  ::  via %notes-action from the client). Direct cast works for all a-notebook arms.
  ;;(c-notebook:n nb-act)
::
::  +get-book: lookup a notebook entry by flag
++  get-book
  |=  =flag:n
  ^-  (unit [=net:n =notebook-state:n])
  (~(get by books) flag)
::
::  +strip-query: drop any query string from a URL tape (returns path portion only)
++  strip-query
  |=  url=tape
  ^-  tape
  =/  qi=(unit @ud)  (find "?" url)
  ?~  qi  url
  (scag u.qi url)
::
::  +can-view-flag: check if ship can view a notebook by flag
++  can-view-flag
  |=  [=flag:n who=ship]
  ^-  ?
  ?~  entry=(get-book flag)  |
  =/  mbrs=members:n
    members.notebook-state.u.entry
  ?~  (~(get by mbrs) who)  |
  &
::
::  +find-flag-by-nid: find the flag for a notebook by numeric notebook id
++  find-flag-by-nid
  |=  nid=@ud
  ^-  flag:n
  =/  matches=(list flag:n)
    %+  murn  ~(tap by books)
    |=  [=flag:n [* =notebook-state:n]]
    ?:  =(nid id.notebook.notebook-state)
      `flag
    ~
  ?~  matches  ~|(notebook-not-found+nid !!)
  i.matches
::
::  +notebooks-changed-card: a fact telling subscribed UIs to re-scry notebooks
++  notebooks-changed-card
  ^-  card
  [%give %fact [/v0/inbox/stream]~ notes-inbox-update+!>(`u-inbox:n`[%notebooks-changed ~])]
::
::  +cleanup-requests: evict in-flight request records that have terminated.
::  Rules (match channels-server in tlon-apps PR 5334):
::    - keep if no terminal result yet, or status is %pending
::    - keep if no final-at timestamp yet (defensive — shouldn't happen)
::    - drop unconditionally past 24h
::    - %ok / %no-change: drop after 5m
::    - %error: drop only after the client has fetched it
++  cleanup-requests
  |=  now=@da
  ^-  requests:v1:n
  %-  ~(rep by requests)
  |=  [[id=request-id:v1:n req=incoming-request:v1:n] out=requests:v1:n]
  ?:  |(?=(~ result.req) ?=([~ %pending *] result.req))
    (~(put by out) id req)
  ?~  final-at.req  (~(put by out) id req)
  ?:  (gth (sub now u.final-at.req) ~d1)
    out
  ?:  |(?=([~ %ok *] result.req) ?=([~ %no-change *] result.req))
    ?:  (gth (sub now u.final-at.req) ~m5)
      out
    (~(put by out) id req)
  ?:  fetched.req  out
  (~(put by out) id req)
::
::  ====  HTTP / request-id helpers  ====
::
::  +http-error: emit a non-200 HTTP error response (plain text body)
++  http-error
  |=  [eyre-id=@ta code=@ud message=@t]
  ^+  cor
  =/  body=octs  (as-octs:mimes:html message)
  %-  emil
  :~  [%give %fact [/http-response/[eyre-id]]~ %http-response-header !>(`response-header:http`[code ~[['content-type' 'text/plain']]])]
      [%give %fact [/http-response/[eyre-id]]~ %http-response-data !>(`body)]
      [%give %kick [/http-response/[eyre-id]]~ ~]
  ==
::
::  +give-http-response: emit a 200 application/json HTTP response carrying
::  the encoded response.
++  give-http-response
  |=  [eyre-id=@ta =response:v1:n]
  ^+  cor
  =/  =json  (response:v1:enjs:notes-json response)
  =/  body=octs  (as-octs:mimes:html (en:json:html json))
  %-  emil
  :~  [%give %fact [/http-response/[eyre-id]]~ %http-response-header !>(`response-header:http`[200 ~[['content-type' 'application/json']]])]
      [%give %fact [/http-response/[eyre-id]]~ %http-response-data !>(`body)]
      [%give %kick [/http-response/[eyre-id]]~ ~]
  ==
::
::  +finalize-request: store terminal body in the request record, fact it on
::  the per-request SSE path, deliver to a held HTTP request if any, and clear
::  http-id so a later late-arriving update doesn't re-deliver.
++  finalize-request
  |=  [rid=request-id:v1:n body=response-body:v1:n]
  ^+  cor
  ?~  req=(~(get by requests) rid)  cor
  =/  =response:v1:n  [rid body]
  =.  requests
    %+  ~(put by requests)  rid
    u.req(result `body, final-at `now.bowl)
  =.  cor
    %-  give
    [%fact ~[/v1/request/(scot %uv rid)] notes-response-1+!>(response)]
  ?~  http-id.u.req  cor
  =.  requests
    %+  ~(put by requests)  rid
    u.req(http-id ~, result `body, final-at `now.bowl)
  (give-http-response u.http-id.u.req response)
::
::  +finalize-pending: deliver %pending status to a held HTTP request when the
::  per-request timeout fires before any terminal response. Keeps the request
::  open for the SSE subscribers + a future late response.
++  finalize-pending
  |=  rid=request-id:v1:n
  ^+  cor
  ?~  req=(~(get by requests) rid)  cor
  ?:  ?&  ?=(^ result.u.req)
          !?=([~ %pending *] result.u.req)
      ==
    cor
  =/  body=response-body:v1:n  [%pending poke-status.u.req]
  =/  =response:v1:n  [rid body]
  =.  requests
    %+  ~(put by requests)  rid
    u.req(result `body)
  =.  cor
    %-  give
    [%fact ~[/v1/request/(scot %uv rid)] notes-response-1+!>(response)]
  ?~  http-id.u.req  cor
  =.  requests
    (~(put by requests) rid u.req(http-id ~))
  (give-http-response u.http-id.u.req response)
::
::  +register-request: idempotent insert of a fresh incoming-request record.
++  register-request
  |=  [rid=request-id:v1:n eyre-id=(unit @ta)]
  ^+  cor
  =/  existing=(unit incoming-request:v1:n)  (~(get by requests) rid)
  ?^  existing  cor
  =.  requests
    (~(put by requests) rid [rid eyre-id %sending ~ ~ |])
  cor
::
::  +give-inbox-received: emit an invite-received event on /v0/inbox/stream
++  give-inbox-received
  |=  [=flag:n from=ship sent-at=@da title=@t]
  ^+  cor
  %-  give
  [%fact [/v0/inbox/stream]~ notes-inbox-update+!>(`u-inbox:n`[%invite-received flag from sent-at title])]
::
::  +give-inbox-removed: emit an invite-removed event on /v0/inbox/stream
++  give-inbox-removed
  |=  =flag:n
  ^+  cor
  %-  give
  [%fact [/v0/inbox/stream]~ notes-inbox-update+!>(`u-inbox:n`[%invite-removed flag])]
::
::  ====  se-core: server/host core  ====
::
++  se-core
  |_  $:  =flag:n
          =log:n
          =notebook-state:n
          gone=_|
          rid=request-id:v1:n
          last-update=(unit update:n)
          finalized=?
      ==
  ++  se-core  .
  ++  emit  |=(=card se-core(cor cor(cards [card cards])))
  ++  give  |=(=gift:agent:gall (emit %give gift))
  ::
  ::  +se-init: initialize for a brand-new notebook
  ++  se-init
    |=  act=action:n
    ^+  se-core
    ?>  ?=(%create-notebook -.act)
    =/  nid=@ud  +(next-id)
    =/  =flag:n  [our.bowl (slugify title.act nid)]
    se-core(flag flag)
  ::
  ::  +se-abed: load from state for a given flag
  ++  se-abed
    |=  =flag:n
    ^+  se-core
    ?>  =(ship.flag our.bowl)
    ?~  entry=(~(get by books) flag)
      ~|(se-abed-not-found+flag !!)
    =/  [=net:n =notebook-state:n]  u.entry
    ?>  ?=(%pub -.net)
    se-core(flag flag, log log.net, notebook-state notebook-state)
  ::
  ::  +se-abet: write back to cor
  ++  se-abet
    ^+  cor
    =.  books
      ?:  gone
        (~(del by books) flag)
      (~(put by books) flag [[%pub log] notebook-state])
    cor
  ::
  ++  se-area
    `path`/v0/notes/(scot %p ship.flag)/[name.flag]
  ::
  ++  se-sub-path
    `path`(weld se-area /updates)
  ::
  ::  +se-update: append update to log and broadcast to subscribers.
  ::  Also records the [time u-notebook] as last-update so se-emit-final-response
  ::  can wrap it in the response-update body for the v1 request flow.
  ++  se-update
    |=  upd=u-notebook:n
    ^+  se-core
    =/  ts=@da
      |-
      ?~  existing=(get:log-on:n log now.bowl)  now.bowl
      $(now.bowl `@da`(add now.bowl ^~((div ~s1 (bex 16)))))
    =.  log  (put:log-on:n log [ts upd])
    =.  last-update  `[ts upd]
    %-  give
    :+  %fact  ~[se-sub-path (weld se-area /stream)]
    notes-response+!>(`response:n`[%update flag [ts upd]])
  ::
  ::  +se-poke-v1: dispatch a c-notes command for a request-id'd flow.
  ::  Sets rid into se-core's door state, runs the normal se-poke, then
  ::  emits the terminal response-update on the per-request host path.
  ++  se-poke-v1
    |=  [req-id=request-id:v1:n cmd=c-cmd:n]
    ^+  se-core
    =.  rid  req-id
    =.  last-update  ~
    =.  finalized  |
    =.  se-core  (se-poke cmd)
    se-emit-final-response
  ::
  ::  +se-emit-final-response: emit response-update on the request path.
  ::  Skipped if rid is 0 (non-v1 flow) or already explicitly finalized.
  ++  se-emit-final-response
    ^+  se-core
    ?:  =(0 rid)  se-core
    ?:  finalized  se-core
    =/  body=response-update-body:v1:n
      ?~  last-update  [%no-change ~]
      [%ok u.last-update]
    =/  =path
      :+  %v1  %notes
      /(scot %p ship.flag)/[name.flag]/request/(scot %p src.bowl)/(scot %uv rid)
    %-  give
    [%fact ~[path] notes-response-update-1+!>(`response-update:v1:n`[rid body])]
  ::
  ::  +se-finalize-with: explicit early-finalize. Use for typed errors so the
  ::  arm can emit %error response-update without crashing (which would also
  ::  discard the response-update emission).
  ++  se-finalize-with
    |=  body=response-update-body:v1:n
    ^+  se-core
    ?:  =(0 rid)  se-core
    =.  finalized  &
    =/  =path
      :+  %v1  %notes
      /(scot %p ship.flag)/[name.flag]/request/(scot %p src.bowl)/(scot %uv rid)
    %-  give
    [%fact ~[path] notes-response-update-1+!>(`response-update:v1:n`[rid body])]
  ::
  ::  +se-watch-sub: send initial snapshot to a new subscriber (with visibility)
  ++  se-watch-sub
    |=  who=ship
    ^+  se-core
    %-  give
    [%fact ~ notes-response+!>(`response:n`[%snapshot flag visibility.notebook-state notebook-state])]
  ::
  ::  +se-watch: handle remote-subscriber watch (dispatch from top-level +watch)
  ++  se-watch
    ^+  se-core
    ?>  =(our.bowl ship.flag)
    ?>  (se-can-view src.bowl)
    (se-watch-sub src.bowl)
  ::
  ++  se-can-view
    |=  who=ship
    ^-  ?
    ?~  (~(get by members.notebook-state) who)  |
    &
  ::
  ++  se-can-edit
    |=  who=ship
    ^-  ?
    =/  r=(unit role:n)
      (~(get by members.notebook-state) who)
    ?~  r  |
    ?|  =(u.r %owner)
        =(u.r %editor)
    ==
  ::
  ++  se-is-owner
    |=  who=ship
    ^-  ?
    =/  r=(unit role:n)
      (~(get by members.notebook-state) who)
    ?~  r  |
    =(u.r %owner)
  ::
  ++  se-visibility
    ^-  visibility:n
    visibility.notebook-state
  ::
  ::  +se-create-notebook: handle %create-notebook action
  ::  nid is +(next-id) — same value se-init used to build the flag slug;
  ::  state has not been modified between se-init and this call.
  ++  se-create-notebook
    |=  act=action:n
    ^+  se-core
    ?>  ?=(%create-notebook -.act)
    =/  nid=@ud  +(next-id)
    =/  rfid=@ud  +(nid)
    =/  =notebook:n
      [nid title.act [our now now our]:bowl]
    =/  nb-state=notebook-state:n
      :*  notebook
          (~(put by *members:n) our.bowl %owner)
          %private
          (~(put by *(map @ud folder:n)) rfid [rfid nid '/' ~ [our now now our]:bowl])
          ~
          ~
      ==
    =.  next-id  rfid
    =.  notebook-state  nb-state
    =.  books
      (~(put by books) flag [[%pub *log:n] notebook-state])
    =.  se-core  (emit notebooks-changed-card)
    (se-update [%created notebook %private])
  ::
  ::  +se-poke: dispatch a c-notes command to the right handler
  ++  se-poke
    |=  cmd=c-cmd:n
    ^+  se-core
    ?-  -.c-notebook.cmd
        %rename            (se-rename-notebook cmd)
        %delete            (se-delete-notebook cmd)
        %visibility        (se-set-visibility cmd)
        %invite            (se-invite cmd)
        %create-folder     (se-create-folder cmd)
        %folder            (se-dispatch-folder cmd)
        %create-note       (se-create-note cmd)
        %note              (se-dispatch-note cmd)
        %batch-import      (se-batch-import cmd)
        %batch-import-tree  (se-batch-import-tree cmd)
        %member-join       (se-member-join cmd)
        %member-leave      (se-member-leave cmd)
    ==
  ::
  ++  se-rename-notebook
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%rename -.c-notebook.cmd)
    ?>  (se-is-owner src.bowl)
    =.  notebook.notebook-state
      %_  notebook.notebook-state
        title       title.c-notebook.cmd
        updated-at  now.bowl
        updated-by  src.bowl
      ==
    (se-update [%updated notebook.notebook-state])
  ::
  ++  se-delete-notebook
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%delete -.c-notebook.cmd)
    ?>  (se-is-owner src.bowl)
    ::  clean up published entries for this notebook
    =.  published
      %-  malt
      %+  skip  ~(tap by published)
      |=  [k=[=flag:n note-id=@ud] v=@t]
      =(flag.k flag)
    ::  history and visibility live in notebook-state, deleted via gone flag
    =.  se-core  (se-update [%deleted ~])
    se-core(gone &)
  ::
  ++  se-set-visibility
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%visibility -.c-notebook.cmd)
    ?>  (se-is-owner src.bowl)
    =.  visibility.notebook-state  visibility.c-notebook.cmd
    (se-update [%visibility visibility.c-notebook.cmd])
  ::
  ++  se-invite
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%invite -.c-notebook.cmd)
    ?>  (se-is-owner src.bowl)
    =*  who  who.c-notebook.cmd
    ?:  (~(has by members.notebook-state) who)
      se-core
    =.  members.notebook-state
      (~(put by members.notebook-state) who %editor)
    (se-update [%member-joined who %editor])
  ::
  ++  se-member-join
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%member-join -.c-notebook.cmd)
    ::  private notebooks reject joins from non-members
    ?:  ?&  =(%private se-visibility)
            !(se-can-view src.bowl)
        ==
      ~|(notebook-private+flag !!)
    =.  members.notebook-state
      (~(put by members.notebook-state) src.bowl %editor)
    (se-update [%member-joined src.bowl %editor])
  ::
  ++  se-member-leave
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%member-leave -.c-notebook.cmd)
    =.  members.notebook-state
      (~(del by members.notebook-state) src.bowl)
    (se-update [%member-left src.bowl])
  ::
  ++  se-dispatch-folder
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%folder -.c-notebook.cmd)
    ?-  -.a-folder.c-notebook.cmd
      %rename  (se-rename-folder cmd)
      %move    (se-move-folder cmd)
      %delete  (se-delete-folder cmd)
    ==
  ::
  ++  se-dispatch-note
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%note -.c-notebook.cmd)
    ?-  -.a-note.c-notebook.cmd
      %rename   (se-rename-note cmd)
      %move     (se-move-note cmd)
      %delete   (se-delete-note cmd)
      %update   (se-update-note cmd)
      %publish  se-core  ::  handled pre-dispatch (local-only)
      %unpublish  se-core
      %restore  (se-restore-note cmd)
    ==
  ::
  ++  se-create-folder
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%create-folder -.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =/  fid=@ud  +(next-id)
    =.  next-id  fid
    =/  =folder:n
      [fid id.notebook.notebook-state name.c-notebook.cmd parent.c-notebook.cmd [src now now src]:bowl]
    =.  folders.notebook-state
      (~(put by folders.notebook-state) fid folder)
    (se-update [%folder fid [%created folder]])
  ::
  ++  se-rename-folder
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%folder -.c-notebook.cmd)
    ?>  ?=(%rename -.a-folder.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =*  fid  id.c-notebook.cmd
    =/  fld=folder:n
      (~(got by folders.notebook-state) fid)
    =.  fld  fld(name name.a-folder.c-notebook.cmd, updated-at now.bowl, updated-by src.bowl)
    =.  folders.notebook-state
      (~(put by folders.notebook-state) fid fld)
    (se-update [%folder fid [%updated fld]])
  ::
  ++  se-move-folder
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%folder -.c-notebook.cmd)
    ?>  ?=(%move -.a-folder.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =*  fid  id.c-notebook.cmd
    =*  new-parent  new-parent.a-folder.c-notebook.cmd
    =/  fld=folder:n
      (~(got by folders.notebook-state) fid)
    =/  subtree=(set @ud)
      (se-subtree-folder-ids fid)
    ?<  (~(has in subtree) new-parent)
    =.  fld  fld(parent-folder-id `new-parent, updated-at now.bowl, updated-by src.bowl)
    =.  folders.notebook-state
      (~(put by folders.notebook-state) fid fld)
    (se-update [%folder fid [%updated fld]])
  ::
  ++  se-delete-folder
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%folder -.c-notebook.cmd)
    ?>  ?=(%delete -.a-folder.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =*  fid  id.c-notebook.cmd
    =/  fld=folder:n
      (~(got by folders.notebook-state) fid)
    ?>  ?=(^ parent-folder-id.fld)
    ?:  recursive.a-folder.c-notebook.cmd
      =/  del-fids=(set @ud)
        (se-subtree-folder-ids fid)
      =/  del-nids=(set @ud)
        (se-note-ids-in-folder-set del-fids)
      =.  folders.notebook-state
        %-  ~(rep in del-fids)
        |=  [f=@ud acc=_folders.notebook-state]
        (~(del by acc) f)
      =.  notes.notebook-state
        %-  ~(rep in del-nids)
        |=  [n=@ud acc=_notes.notebook-state]
        (~(del by acc) n)
      (se-update [%folder fid [%deleted ~]])
    ::  non-recursive: fail if has children
    =/  children=(list @ud)
      (se-folder-children-ids fid)
    ?>  =(~ children)
    =/  child-notes=(list note:n)
      (se-notes-in-folder fid)
    ?>  =(~ child-notes)
    =.  folders.notebook-state
      (~(del by folders.notebook-state) fid)
    (se-update [%folder fid [%deleted ~]])
  ::
  ++  se-create-note
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%create-note -.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =*  fid  folder.c-notebook.cmd
    =/  fld=folder:n
      (~(got by folders.notebook-state) fid)
    =/  nid=@ud  +(next-id)
    =.  next-id  nid
    =/  =note:n
      :*  nid
          id.notebook.notebook-state
          fid
          title.c-notebook.cmd
          ~
          body.c-notebook.cmd
          src.bowl
          now.bowl
          src.bowl
          now.bowl
          0
      ==
    =.  notes.notebook-state
      (~(put by notes.notebook-state) nid note)
    (se-update [%note nid [%created note]])
  ::
  ++  se-rename-note
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%note -.c-notebook.cmd)
    ?>  ?=(%rename -.a-note.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =*  nid  id.c-notebook.cmd
    =/  =note:n  (~(got by notes.notebook-state) nid)
    ::  Title changes do NOT bump revision. The revision counter tracks
    ::  body-md only — that's what optimistic concurrency on update-note
    ::  cares about. Bumping rev on rename silently desynced auto-save
    ::  (which sends body+rename back-to-back) by leaving the server at
    ::  rev+1 while the client believed it was still at rev.
    =.  note
      %_  note
        title       title.a-note.c-notebook.cmd
        updated-by  src.bowl
        updated-at  now.bowl
      ==
    =.  notes.notebook-state
      (~(put by notes.notebook-state) nid note)
    (se-update [%note nid [%updated note]])
  ::
  ++  se-move-note
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%note -.c-notebook.cmd)
    ?>  ?=(%move -.a-note.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =*  nid  id.c-notebook.cmd
    =/  =note:n  (~(got by notes.notebook-state) nid)
    ::  Move does NOT bump revision; same reasoning as rename — body-md
    ::  is the only field that drives optimistic concurrency.
    =.  note
      %_  note
        folder-id   folder.a-note.c-notebook.cmd
        updated-by  src.bowl
        updated-at  now.bowl
      ==
    =.  notes.notebook-state
      (~(put by notes.notebook-state) nid note)
    (se-update [%note nid [%updated note]])
  ::
  ++  se-delete-note
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%note -.c-notebook.cmd)
    ?>  ?=(%delete -.a-note.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =*  nid  id.c-notebook.cmd
    =/  =note:n
      (~(got by notes.notebook-state) nid)
    =.  notes.notebook-state
      (~(del by notes.notebook-state) nid)
    (se-update [%note nid [%deleted ~]])
  ::
  ++  se-update-note
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%note -.c-notebook.cmd)
    ?>  ?=(%update -.a-note.c-notebook.cmd)
    =*  nid  id.c-notebook.cmd
    =/  =note:n
      (~(got by notes.notebook-state) nid)
    ?>  (se-can-edit src.bowl)
    ::  strict optimistic concurrency check (no force-update sentinel)
    ?:  !=(revision.note expected-revision.a-note.c-notebook.cmd)
      ~|(%revision-mismatch !!)
    ::  no-op early-out: body unchanged
    ?:  =(body-md.note body.a-note.c-notebook.cmd)
      se-core
    ::  archive the prior revision into per-notebook history
    =/  prior=note-revision:n
      :*  rev=revision.note
          at=now.bowl
          author=src.bowl
          title=title.note
          body-md=body-md.note
      ==
    =/  existing=(list note-revision:n)
      (fall (~(get by history.notebook-state) nid) ~)
    =.  history.notebook-state
      (~(put by history.notebook-state) nid [prior existing])
    =.  note
      %_  note
        body-md     body.a-note.c-notebook.cmd
        updated-by  src.bowl
        updated-at  now.bowl
        revision    +(revision.note)
      ==
    =.  notes.notebook-state
      (~(put by notes.notebook-state) nid note)
    ::  emit archive event first, then update
    =.  se-core
      (se-update [%note nid [%history-archived prior]])
    (se-update [%note nid [%updated note]])
  ::
  ::  +se-restore-note: revert to a prior archived revision
  ::  This is simply an update with the archived body, respecting current revision.
  ++  se-restore-note
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%note -.c-notebook.cmd)
    ?>  ?=(%restore -.a-note.c-notebook.cmd)
    =*  nid  id.c-notebook.cmd
    =/  =note:n
      (~(got by notes.notebook-state) nid)
    ?>  (se-can-edit src.bowl)
    ::  find the archived revision in per-notebook history
    =/  revs=(list note-revision:n)
      (fall (~(get by history.notebook-state) nid) ~)
    =/  found=(unit note-revision:n)
      |-
      ?~  revs  ~
      ?:  =(rev.i.revs rev.a-note.c-notebook.cmd)
        `i.revs
      $(revs t.revs)
    ?>  ?=(^ found)
    ::  apply as a normal update with current revision as expected
    (se-update-note `c-cmd:n`[flag [%note nid [%update body-md.u.found revision.note]]])
  ::
  ++  se-batch-import
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%batch-import -.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =/  items=(list [title=@t body=@t])  notes.c-notebook.cmd
    |-  ^+  se-core
    ?~  items  se-core
    =/  nid=@ud  +(next-id)
    =.  next-id  nid
    =/  =note:n
      :*  nid
          id.notebook.notebook-state
          folder.c-notebook.cmd
          title.i.items
          ~
          body.i.items
          src.bowl
          now.bowl
          src.bowl
          now.bowl
          0
      ==
    =.  notes.notebook-state
      (~(put by notes.notebook-state) nid note)
    =.  se-core  (se-update [%note nid [%created note]])
    $(items t.items, se-core se-core)
  ::
  ++  se-batch-import-tree
    |=  cmd=c-cmd:n
    ^+  se-core
    ?>  ?=(%batch-import-tree -.c-notebook.cmd)
    ?>  (se-can-edit src.bowl)
    =/  items=(list import-node:n)  tree.c-notebook.cmd
    =*  nid-nb  id.notebook.notebook-state
    =|  stack=(list [remaining=(list import-node:n) folder-id=@ud])
    =/  fid=@ud  parent.c-notebook.cmd
    |-  ^+  se-core
    ?~  items
      ?~  stack
        se-core
      $(items remaining.i.stack, fid folder-id.i.stack, stack t.stack)
    ?-  -.i.items
        %note
      =/  nid=@ud  +(next-id)
      =.  next-id  nid
      =/  =note:n
        :*  nid
            nid-nb
            fid
            title.i.items
            ~
            body-md.i.items
            src.bowl
            now.bowl
            src.bowl
            now.bowl
            0
        ==
      =.  notes.notebook-state
        (~(put by notes.notebook-state) nid note)
      =.  se-core  (se-update [%note nid [%created note]])
      $(items t.items, se-core se-core)
    ::
        %folder
      =/  new-fid=@ud  +(next-id)
      =.  next-id  new-fid
      =/  =folder:n
        [new-fid nid-nb name.i.items `fid [src now now src]:bowl]
      =.  folders.notebook-state
        (~(put by folders.notebook-state) new-fid folder)
      =.  se-core  (se-update [%folder new-fid [%created folder]])
      $(items children.i.items, stack [[t.items fid] stack], fid new-fid, se-core se-core)
    ==
  ::
  ::  helpers
  ++  se-folder-children-ids
    |=  folder-id=@ud
    ^-  (list @ud)
    %+  murn  ~(tap by folders.notebook-state)
    |=  [fid=@ud fld=folder:n]
    ?~  parent-folder-id.fld  ~
    ?:  =(u.parent-folder-id.fld folder-id)
      `fid
    ~
  ::
  ++  se-subtree-folder-ids
    |=  folder-id=@ud
    ^-  (set @ud)
    =/  acc=(set @ud)  (silt ~[folder-id])
    =/  queue=(list @ud)  ~[folder-id]
    |-
    ?~  queue  acc
    =/  children=(list @ud)  (se-folder-children-ids i.queue)
    %=  $
      queue  (weld t.queue children)
      acc    (~(gas in acc) children)
    ==
  ::
  ++  se-note-ids-in-folder-set
    |=  fids=(set @ud)
    ^-  (set @ud)
    %-  silt
    %+  murn  ~(tap by notes.notebook-state)
    |=  [nid=@ud =note:n]
    ?:  (~(has in fids) folder-id.note)
      `nid
    ~
  ::
  ++  se-notes-in-folder
    |=  folder-id=@ud
    ^-  (list note:n)
    %+  murn  ~(tap by notes.notebook-state)
    |=  [nid=@ud =note:n]
    ?:  =(folder-id.note folder-id)
      `note
    ~
  --
::
::  ====  no-core: subscriber/client core  ====
::
++  no-core
  |_  [=flag:n =net:n =notebook-state:n gone=_|]
  ++  no-core  .
  ++  emit  |=(=card no-core(cor cor(cards [card cards])))
  ++  give  |=(=gift:agent:gall (emit %give gift))
  ::
  ::  +no-req-watch-path: path the subscriber subscribes to on the host
  ++  no-req-watch-path
    |=  rid=request-id:v1:n
    ^-  path
    :+  %v1  %notes
    /(scot %p ship.flag)/[name.flag]/request/(scot %p our.bowl)/(scot %uv rid)
  ::
  ::  +no-req-watch-wire: subscriber-side wire for the watch on host path.
  ::  Flag is embedded so signs landing here can be routed back to the
  ::  right no-core context without a separate lookup map.
  ++  no-req-watch-wire
    |=  rid=request-id:v1:n
    ^-  wire
    /notes/req/(scot %p ship.flag)/[name.flag]/(scot %uv rid)/watch
  ::
  ::  +no-req-poke-wire: subscriber-side wire for the poke to host
  ++  no-req-poke-wire
    |=  rid=request-id:v1:n
    ^-  wire
    /notes/req/(scot %p ship.flag)/[name.flag]/(scot %uv rid)/poke
  ::
  ::  +no-req-wake-wire: per-request timeout behn wire
  ++  no-req-wake-wire
    |=  rid=request-id:v1:n
    ^-  wire
    /notes/req/(scot %p ship.flag)/[name.flag]/(scot %uv rid)/wake
  ::
  ++  no-abed
    |=  =flag:n
    ^+  no-core
    ?~  entry=(~(get by books) flag)
      ~|(no-abed-not-found+flag !!)
    =/  [=net:n =notebook-state:n]  u.entry
    no-core(flag flag, net net, notebook-state notebook-state)
  ::
  ++  no-abet
    ^+  cor
    =.  books
      ?:  gone
        (~(del by books) flag)
      (~(put by books) flag [net notebook-state])
    cor
  ::
  ++  no-area
    `path`/notes/sub/(scot %p ship.flag)/[name.flag]
  ::
  ++  no-sub-wire
    `path`/notes/sub/(scot %p ship.flag)/[name.flag]
  ::
  ++  no-sub-path
    `path`/v0/notes/(scot %p ship.flag)/[name.flag]/updates
  ::
  ::  +no-action: convert local action to c-notes and send poke to host.
  ::  Works for both %pub and %sub net — if host==our.bowl, Gall loops it back.
  ++  no-action
    |=  act=action:n
    ^+  no-core
    ?>  ?=(%notebook -.act)
    =/  cmd=command:n
      [%notebook flag.act (a-notebook-to-c-notebook a-notebook.act)]
    %-  emit
    :*  %pass
        no-sub-wire
        %agent
        [ship.flag %notes]
        %poke
        notes-command+!>(cmd)
    ==
  ::
  ::  +no-action-v1: subscribe to host's per-request path, poke host with
  ::  the v1 command (carrying request-id), schedule a per-request behn
  ::  timeout. The host's response-update will arrive on the watch wire,
  ::  flow through +agent → +no-agent-req to finalize the request.
  ::
  ::  For self-hosted notebooks (ship.flag == our.bowl) this loops through
  ::  Gall — uniform code path at the cost of one extra event hop.
  ++  no-action-v1
    |=  [rid=request-id:v1:n act=action:n]
    ^+  no-core
    ?>  ?=(%notebook -.act)
    =/  cmd1=command:v1:n
      [rid [%notebook flag.act (a-notebook-to-c-notebook a-notebook.act)]]
    =.  no-core
      %-  emit
      :*  %pass  (no-req-watch-wire rid)
          %agent  [ship.flag %notes]
          %watch  (no-req-watch-path rid)
      ==
    =.  no-core
      %-  emit
      :*  %pass  (no-req-poke-wire rid)
          %agent  [ship.flag %notes]
          %poke  notes-command-1+!>(cmd1)
      ==
    %-  emit
    [%pass (no-req-wake-wire rid) %arvo %b %wait (add now.bowl ~s20)]
  ::
  ::  +no-agent-req-watch: handle signs on /notes/req/<uv>/watch wire.
  ::  watch-ack: nack finalizes %not-authorized. fact: response-update
  ::  from host, transform to response and finalize.
  ++  no-agent-req-watch
    |=  [rid=request-id:v1:n =sign:agent:gall]
    ^+  no-core
    ?+  -.sign  no-core
        %watch-ack
      ?~  p.sign  no-core
      =.  cor  (finalize-request rid [%error %not-authorized u.p.sign])
      no-core
    ::
        %fact
      ?.  =(p.cage.sign %notes-response-update-1)
        no-core
      =+  !<(ru=response-update:v1:n q.cage.sign)
      =/  body=response-body:v1:n
        ?-  -.body.ru
          %no-change  [%no-change ~]
          %ok         [%ok %update flag update.body.ru]
          %error      [%error type.body.ru message.body.ru]
        ==
      =.  cor  (finalize-request rid body)
      ::  leave the host watch — we got our terminal response
      %-  emit
      [%pass (no-req-watch-wire rid) %agent [ship.flag %notes] %leave ~]
    ::
        %kick
      no-core
    ==
  ::
  ::  +no-agent-req-poke: handle poke-ack on /notes/req/<uv>/poke wire.
  ::  nack → finalize %unknown + leave host watch. ack → mark poke-status.
  ++  no-agent-req-poke
    |=  [rid=request-id:v1:n =sign:agent:gall]
    ^+  no-core
    ?+  -.sign  no-core
        %poke-ack
      ?~  p.sign
        ?~  req=(~(get by requests) rid)  no-core
        =.  requests
          (~(put by requests) rid u.req(poke-status %acked))
        no-core
      =?  requests  ?=(^ (~(get by requests) rid))
        =/  u  (~(got by requests) rid)
        (~(put by requests) rid u(poke-status %nacked))
      =.  cor  (finalize-request rid [%error %unknown u.p.sign])
      %-  emit
      [%pass (no-req-watch-wire rid) %agent [ship.flag %notes] %leave ~]
    ==
  ::
  ++  no-start-watch
    ^+  no-core
    ?>  ?=(%sub -.net)
    %-  emit
    [%pass no-sub-wire %agent [ship.flag %notes] %watch no-sub-path]
  ::
  ++  no-leave
    ^+  no-core
    ?>  ?=(%sub -.net)
    =.  gone  &
    %-  emit
    [%pass no-sub-wire %agent [ship.flag %notes] %leave ~]
  ::
  ::  +no-publish: cache HTML for a note in this notebook so this ship's
  ::  /notes/pub/<flag>/<note-id> serves it. Self-check is enforced at the
  ::  action-poke layer (?> =(our.bowl src.bowl)); no-abed has already
  ::  validated that the notebook exists. No further permission gating —
  ::  publishing is a per-ship cache write, not an authority assertion.
  ++  no-publish
    |=  [nid=@ud html=@t]
    ^+  no-core
    =.  published  (~(put by published) [flag nid] html)
    no-core
  ::
  ::  +no-unpublish: remove a previously-published note's cached HTML.
  ++  no-unpublish
    |=  nid=@ud
    ^+  no-core
    =.  published  (~(del by published) [flag nid])
    no-core
  ::
  ::  +no-agent: handle sign on the [%notes %sub ship name ~] wire.
  ::  Used by both pub and sub: when we host (pub), self-pokes from the
  ::  action handler flow back as %poke-ack on this wire; when we sub,
  ::  the host sends %fact / %kick / %watch-ack here.
  ++  no-agent
    |=  =sign:agent:gall
    ^+  no-core
    ?+  -.sign  no-core
        %fact
      =/  =response:n  !<(response:n q.cage.sign)
      (no-response response)
    ::
        %kick
      ?.  ?=(%sub -.net)  no-core
      %-  emit
      :*  %pass
          no-sub-wire
          %agent
          [ship.flag %notes]
          %watch
          no-sub-path
      ==
    ::
        %watch-ack
      ?~  p.sign  no-core
      ?.  ?=(%sub -.net)  no-core
      =.  net  net(init |)
      ::  Schedule a retry. The host (or network) may have transiently
      ::  failed; without this, a single bad watch-ack leaves the
      ::  subscription dead until the user manually rejoins.
      %-  emit
      :*  %pass
          /notes/rewatch/(scot %p ship.flag)/[name.flag]
          %arvo  %b  %wait  (add now.bowl ~s30)
      ==
    ==
  ::
  ::  +no-response: apply an update from the host to local state
  ++  no-response
    |=  =response:n
    ^+  no-core
    ?-  -.response
        %snapshot
      =.  notebook-state  notebook-state.response
      ?>  ?=(%sub -.net)
      =.  net  net(init &)
      =.  cards  [notebooks-changed-card cards]
      %-  give
      [%fact [/v0/notes/(scot %p ship.flag)/[name.flag]/stream]~ notes-response+!>(response)]
    ::
        %update
      =.  no-core  (no-apply-update flag.response update.response)
      %-  give
      [%fact [/v0/notes/(scot %p ship.flag)/[name.flag]/stream]~ notes-response+!>(response)]
    ==
  ::
  ::  +no-apply-update: apply a single u-notebook update to local state
  ++  no-apply-update
    |=  [=flag:n upd=update:n]
    ^+  no-core
    ?-  -.u-notebook.upd
        %created
      =.  notebook.notebook-state  notebook.u-notebook.upd
      no-core
    ::
        %updated
      =.  notebook.notebook-state  notebook.u-notebook.upd
      no-core
    ::
        %deleted
      no-core(gone &)
    ::
        %visibility
      ::  write visibility into local notebook-state
      =.  visibility.notebook-state  visibility.u-notebook.upd
      no-core
    ::
        %member-joined
      =.  members.notebook-state
        (~(put by members.notebook-state) who.u-notebook.upd role.u-notebook.upd)
      no-core
    ::
        %member-left
      =.  members.notebook-state
        (~(del by members.notebook-state) who.u-notebook.upd)
      no-core
    ::
        %invite-received
      no-core   :: handled via give-inbox-received on host; no local state
    ::
        %invite-removed
      no-core
    ::
        %folder
      (no-apply-folder-update id.u-notebook.upd u-folder.u-notebook.upd)
    ::
        %note
      (no-apply-note-update id.u-notebook.upd u-note.u-notebook.upd)
    ==
  ::
  ++  no-apply-folder-update
    |=  [fid=@ud upd=u-folder:n]
    ^+  no-core
    ?-  -.upd
        %created
      =.  folders.notebook-state
        (~(put by folders.notebook-state) fid folder.upd)
      no-core
        %updated
      =.  folders.notebook-state
        (~(put by folders.notebook-state) fid folder.upd)
      no-core
        %deleted
      =.  folders.notebook-state
        (~(del by folders.notebook-state) fid)
      no-core
    ==
  ::
  ++  no-apply-note-update
    |=  [nid=@ud upd=u-note:n]
    ^+  no-core
    ?-  -.upd
        %created
      =.  notes.notebook-state
        (~(put by notes.notebook-state) nid note.upd)
      no-core
        %updated
      =.  notes.notebook-state
        (~(put by notes.notebook-state) nid note.upd)
      no-core
        %deleted
      =.  notes.notebook-state
        (~(del by notes.notebook-state) nid)
      no-core
        %published
      no-core   :: host-side only; subscriber doesn't track published state
        %unpublished
      no-core
        %history-archived
      ::  append archived revision to local per-notebook history cache
      =/  existing=(list note-revision:n)
        (fall (~(get by history.notebook-state) nid) ~)
      =.  history.notebook-state
        (~(put by history.notebook-state) nid [note-revision.upd existing])
      no-core
    ==
  ::
  ::  +no-peek: handle per-notebook scry requests
  ::  kind: the path segment after /v0/ (e.g. %notebook, %notes, %note, etc.)
  ::  rest: the remainder of the pole after kind/ship/name (typed as *)
  ++  no-peek
    |=  [kind=@ rest=*]
    ^-  (unit (unit cage))
    ?>  ?=(^ (~(get by members.notebook-state) src.bowl))
    ?+  kind  ~
        %notebook
      =/  nd=notebook-detail:n  [flag notebook.notebook-state visibility.notebook-state]
      ``notes-notebook+!>(nd)
    ::
        %folders
      =/  flds=(list folder:n)
        ~(val by folders.notebook-state)
      ``notes-folders+!>(flds)
    ::
        %notes
      =/  nts=(list note:n)
        ~(val by notes.notebook-state)
      ``notes-notes+!>(nts)
    ::
        %note
      =/  nid=@ud  (slav %ud ;;(@ -.rest))
      ?~  note=(~(get by notes.notebook-state) nid)
        ~
      ``notes-note+!>(u.note)
    ::
        %note-history
      =/  nid=@ud  (slav %ud ;;(@ -.rest))
      =/  revs=(list note-revision:n)
        (fall (~(get by history.notebook-state) nid) ~)
      ``notes-note-history+!>(revs)
    ::
        %folder
      =/  fid=@ud  (slav %ud ;;(@ -.rest))
      ?~  fld=(~(get by folders.notebook-state) fid)
        ~
      ``notes-folder+!>(u.fld)
    ::
        %members
      =/  mrecords=(list member-record:n)
        %+  turn  ~(tap by members.notebook-state)
        |=  [who=ship r=role:n]
        [who r]
      ``notes-members+!>(mrecords)
    ==
  ::
  ::  +no-watch: handle local UI stream subscription for this notebook
  ++  no-watch
    ^+  no-core
    ?>  ?=(^ (~(get by members.notebook-state) src.bowl))
    %-  give
    :+  %fact
      [`path`/v0/notes/(scot %p ship.flag)/[name.flag]/stream]~
    notes-response+!>(`response:n`[%snapshot flag visibility.notebook-state notebook-state])
  --
--
