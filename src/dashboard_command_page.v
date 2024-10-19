import veb
import monitor

fn build_dashboard_command(title string, user User, commands []monitor.CommandWatcher) string {
	return $tmpl('dashboard_command.html')
}

@['/dashboard/command']
pub fn (mut app App) dashboard_command(mut ctx Context) veb.Result {
	if user := app.find_user_by_token(ctx.get_cookie('token') or { '' }) {
		commands := sql app.db {
			select from monitor.CommandWatcher where active == true
		} or {
			eprintln(err.msg())
			ctx.error('Internal error (code 10)')
			return ctx.redirect('/')
		}
		return ctx.html(build_dashboard_command('vonitor', user, commands))
	}
	return ctx.redirect('/')
}
