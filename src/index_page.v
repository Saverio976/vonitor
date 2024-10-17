import veb

fn build_index_not_connected(title string) string {
	return $tmpl('index_notconnected.html')
}

pub fn (mut app App) index(mut ctx Context) veb.Result {
	if _ := app.find_user_by_token(ctx.get_cookie('token') or { '' }) {
		return ctx.redirect('/dashboard/file')
	} else {
		return ctx.html(build_index_not_connected('vonitor'))
	}
}
