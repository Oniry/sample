-module(index).
-compile(export_all).
-include_lib("kvs/include/entry.hrl").
-include_lib("nitro/include/nitro.hrl").
-include_lib("n2o/include/n2o.hrl").
body() -> [].
main() -> [].
event(init) ->
    Room = n2o:session(room),
    n2o:reg({topic,Room}),
    nitro:update(heading,#b{id=heading,body="Review: " ++ Room}),
    nitro:update(logout,#button{id=logout, body="Logout " ++ n2o:user(), postback=logout}),
    nitro:update(upload,#upload{id=upload}),
    nitro:update(send, #button{ id=send, body= <<"Chat">>, postback=chat, source=[message] }),
    [ event({client,{E#entry.from,E#entry.media}})
      || E <- kvs:entries(kvs:get(feed,{room,Room}),entry,10) ];
event(logout) ->
    n2o:user([]),
    nitro:redirect("/app/login.htm");
event(chat) ->
    User    = n2o:user(),
    Room    = n2o:session(room),
    Message = n2o:q(message),
    n2o:info(?MODULE,"Chat pressed: ~p~n",[{Room,Message,User}]),
    kvs:add(#entry{id=kvs:next_id("entry",1),from=n2o:user(),
                   feed_id={room,Room},media=Message}),
    n2o:send({topic,Room},#client{data={User,Message}});
event(#client{data={User,Message}}) ->
    HTML = nitro:to_list(Message),
    nitro:wire(#jq{target=message,method=[focus,select]}),
    DTL = #dtl{file="message",app=review,bindings=[{user,User},{color,"gray"},{message,HTML}]},
    nitro:insert_top(history, nitro:jse(nitro:render(DTL)));
event(#ftp{sid=Sid,filename=Filename,status={event,stop}}=Data) ->
    n2o:info(?MODULE,"FTP Delivered ~p~n",[Data]),
    Name = hd(lists:reverse(string:tokens(nitro:to_list(Filename),"/"))),
    erlang:put(message,nitro:render(#link{href=iolist_to_binary(["/app/",Sid,"/",nitro:url_encode(Name)]),body=Name})),
    n2o:info(?MODULE,"Message ~p~n",[wf:q(message)]),
    event(chat);
event(Event) ->
    n2o:info(?MODULE,"Event: ~p", [Event]),
    ok.
