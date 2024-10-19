import veb
import monitor

fn build_dashboard_process(title string, user User, processes []monitor.ProcessWatcher) string {
	return $tmpl('dashboard_process.html')
}

@['/dashboard/process']
pub fn (mut app App) dashboard_process(mut ctx Context) veb.Result {
	if user := app.find_user_by_token(ctx.get_cookie('token') or { '' }) {
		processes := sql app.db {
			select from monitor.ProcessWatcher
		} or {
			eprintln(err.msg())
			ctx.error('Internal error (code 10)')
			return ctx.redirect('/')
		}
		return ctx.html(build_dashboard_process('vonitor', user, processes))
	}
	return ctx.redirect('/')
}
