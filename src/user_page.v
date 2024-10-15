import veb
import x.templating.dtm

@['/user/login']
pub fn (mut app App) user_login(mut ctx Context) veb.Result {
	mut tmpl_var := map[string]dtm.DtmMultiTypeMap{}
	tmpl_var['title'] = "vonitor"
	html_content := app.dtmi.expand('user_login.html', placeholders: &tmpl_var)
	return ctx.html(html_content)
}

@['/user/register']
pub fn (mut app App) user_register(mut ctx Context) veb.Result {
	mut tmpl_var := map[string]dtm.DtmMultiTypeMap{}
	tmpl_var['title'] = "vonitor"
	html_content := app.dtmi.expand('user_register.html', placeholders: &tmpl_var)
	return ctx.html(html_content)
}
