import veb
import x.json2
import crypto.rand

struct ConnectionParam {
mut:
    name string
    password string
}

pub fn (mut app App) find_user_by_name(name string) ?User {
    user := sql app.db {
        select from User where name == name limit 1
    } or {
        return none
    }
    return user.first()
}

pub fn (mut app App) find_user_by_token(token string) ?User {
    user_token := app.auth.find_token(token) or {
        return none
    }
    user := sql app.db {
        select from User where id == user_token.user_id limit 1
    } or {
        return none
    }
    return user.first()
}

@["/api/user/register"; post]
pub fn (mut app App) register_user(mut ctx Context, name string, password string) veb.Result {
    mut name_val := name
    mut password_val := password
    if name_val == '' || password == '' {
        connection_param := json2.decode[ConnectionParam](ctx.req.data) or {
            ctx.error("Can't decode data to json")
            return ctx.redirect('/')
        }
        name_val = connection_param.name
        password_val = connection_param.password
    }
    salt_bytes := rand.bytes(32) or {
        eprintln(err.msg())
        ctx.error('Internal error (code 03)')
        return ctx.redirect('/')
    }
    salt := salt_bytes.hex()
    password_hash := hash_password(password_val, salt) or {
        eprintln(err.msg())
        ctx.error('Internal error (code 04)')
        return ctx.redirect('/')
    }
    new_user := User{
        name:          name_val
        password_hash: password_hash
        salt:          salt
    }
    sql app.db {
        insert new_user into User
    } or {
        eprintln(err.msg())
        ctx.error("Can't create user")
        return ctx.redirect('/')
    }
    if x := app.find_user_by_name(name) {
        token := app.auth.add_token(x.id) or {
            eprintln(err.msg())
            ctx.error('Internal error (code 06)')
            return ctx.redirect('/')
        }
        ctx.set_cookie(name: 'token', value: token, same_site: .same_site_none_mode, secure: true, path: '/')
        return ctx.redirect('/')
    } else {
        eprintln("Can't get user just created")
        ctx.error('Internal error (code 07)')
        return ctx.redirect('/')
    }
}

@["/api/user/login"; post]
pub fn (mut app App) login_post(mut ctx Context, name string, password string) veb.Result {
    mut name_val := name
    mut password_val := password
    if name == '' || password == '' {
        connection_param := json2.decode[ConnectionParam](ctx.req.data) or {
            ctx.error("Can't decode data to json")
            return ctx.redirect('/')
        }
        name_val = connection_param.name
        password_val = connection_param.password
    }
    user := app.find_user_by_name(name_val) or {
        ctx.error('Bad credentials')
        return ctx.redirect('/')
    }
    given_password_hash := hash_password(password_val, user.salt) or {
        eprintln(err.msg())
        ctx.error('Internal error (code 01)')
        return ctx.redirect('/')
    }
    if given_password_hash != user.password_hash {
        ctx.error('Bad credentials')
        return ctx.redirect('/')
    }
    token := app.auth.add_token(user.id) or {
        eprintln(err.msg())
        ctx.error('Internal error (code 02)')
        return ctx.redirect('/')
    }
    ctx.set_cookie(name: 'token', value: token, same_site: .same_site_none_mode, secure: true, path: '/')
    return ctx.redirect('/')
}


