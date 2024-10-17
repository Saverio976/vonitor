import veb

fn build_user_login(title string) string {
	return $tmpl('user_login.html')
}

@['/user/login']
pub fn (mut app App) user_login(mut ctx Context) veb.Result {
	return ctx.html(build_user_login('vonitor'))
}

fn build_user_register(title string) string {
	return $tmpl('user_register.html')
}

@['/user/register']
pub fn (mut app App) user_register(mut ctx Context) veb.Result {
	return ctx.html(build_user_register('vonitor'))
}
