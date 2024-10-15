import veb
import x.templating.dtm

pub fn (mut app App) index(mut ctx Context) veb.Result {
	mut tmpl_var := map[string]dtm.DtmMultiTypeMap{}
	tmpl_var["title"] = "vonitor"
	mut html_content := ''
	if user := app.find_user_by_token(ctx.get_cookie('token') or { '' }) {
		tmpl_var['user_name'] = user.name
		html_content = app.dtmi.expand('index_connected.html', placeholders: &tmpl_var)
	} else {
		html_content = app.dtmi.expand('index_notconnected.html', placeholders: &tmpl_var)
	}
	return ctx.html(html_content)
}
