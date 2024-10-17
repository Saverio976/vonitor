import veb
import monitor

fn build_dashboard_file(title string, user User, files []monitor.FileWatcher) string {
	return $tmpl('dashboard_file.html')
}

@['/dashboard/file']
pub fn (mut app App) dashboard_file(mut ctx Context) veb.Result {
	if user := app.find_user_by_token(ctx.get_cookie('token') or { '' }) {
		files := sql app.db_mon {
			select from monitor.FileWatcher where active == true
		} or {
			eprintln(err.msg())
			ctx.error('Internal error (code 10)')
			return ctx.redirect('/')
		}
		return ctx.html(build_dashboard_file('vonitor', user, files))
	}
	return ctx.redirect('/')
}
