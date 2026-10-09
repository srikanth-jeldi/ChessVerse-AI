'use strict';

function academySignInView() {
  return `<div class="academy-signin"><section class="signin-story" aria-label="ChessVerseAI academy">
    <div class="signin-brand"><img src="app-icon.png" alt="ChessVerseAI king logo"><div>ChessVerseAI<small>by EpitomeHub</small></div></div>
    <div class="signin-message"><p class="signin-eyebrow">THE ACADEMY WORKSPACE</p><h1>Great coaches.<br><span>Brighter futures.</span></h1><p class="signin-description">One home for your students, your coaches, and every next move. Built for chess academies and schools.</p>
    <div class="signin-features">${[['users','Manage','Students'],['chart','Track','Progress'],['coach','Plan','Training'],['trophy','Build','Champions']].map(([i,a,b])=>`<div><span>${icon(i)}</span><p>${a}<br>${b}</p></div>`).join('')}</div></div>
    <div class="signin-story-footer"><blockquote>“Discipline today.<br>Brighter tomorrows.”<cite>— ChessVerseAI</cite></blockquote><p>LEARN &nbsp; PRACTICE &nbsp; IMPROVE &nbsp; SUCCEED</p></div>
    </section><section class="signin-workspace"><div class="signin-access"><span>New to ChessVerseAI?</span><button type="button" data-signin="access">Register academy</button></div>
    <div class="signin-card"><img class="signin-emblem" src="app-icon.png" alt="ChessVerseAI"><h2>Welcome back</h2><p class="signin-subtitle">Sign in to your ChessVerseAI academy workspace</p>
    <form id="login-form"><label class="signin-field"><span class="sr-only">Email or username</span>${icon('users')}<input name="identity" placeholder="Email or username" required autocomplete="username"></label>
    <label class="signin-field"><span class="sr-only">Password</span>${icon('shield')}<input id="academy-password" name="password" type="password" placeholder="Password" required maxlength="72" autocomplete="current-password"><button type="button" class="password-toggle" data-signin="password" aria-label="Show password" aria-pressed="false"><svg class="icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg></button></label>
    <div class="signin-options"><label><input id="remember-identity" type="checkbox"> Remember email</label><button type="button" data-signin="forgot">Forgot password?</button></div>
    <div class="error" role="alert"></div><button class="signin-submit" type="submit">Sign in to workspace ${icon('arrow')}</button></form>
    <div class="signin-divider"><span>OR</span></div><div class="social-signin" aria-label="Social sign in"><div id="academy-google-signin"></div><button class="signin-social facebook" type="button" data-signin="facebook" hidden>Continue with Facebook</button></div><button class="signin-demo" type="button" data-action="demo">${icon('home')} Explore demo academy</button><p class="signin-demo-note">Google and Facebook use the same ChessVerseAI account when the verified email matches.</p></div>
    <footer class="signin-footer">Powered by EpitomeHub<nav class="academy-public-links" aria-label="Academy information"><a href="/academy/pricing">Plans</a><a href="/academy/about">About</a><a href="/academy/contact">Contact</a><a href="/academy/terms">Terms</a><a href="/academy/privacy">Privacy</a><a href="/academy/refunds">Refunds</a></nav><span>More than a game.<br>A brighter future.</span></footer></section></div>`;
}

login = function academySignIn() {
  state.data = null;
  $('#app').innerHTML = academySignInView();
  try {
    const identity = localStorage.getItem('academy-remembered-identity');
    if (identity) {
      $('#login-form [name=identity]').value = identity;
      $('#remember-identity').checked = true;
    }
  } catch { /* Storage may be disabled; authentication still works. */ }
  initializeAcademySocialLogin();
};

let academyOAuthConfig;
async function completeAcademyOAuth(provider,payload){const response=await fetch('/api/auth/'+provider,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});const result=await response.json();if(!response.ok)throw new Error(result.message||provider+' sign-in failed.');state.token=result.token;await start();}
function loadSocialScript(id,src,onload){if(document.querySelector('#'+id)){onload?.();return;}const script=document.createElement('script');script.id=id;script.async=true;script.defer=true;script.crossOrigin='anonymous';script.src=src;script.onload=onload;document.head.append(script);}
async function initializeAcademySocialLogin(){try{academyOAuthConfig=await fetch('/api/auth/oauth-config').then(r=>r.json());if(academyOAuthConfig.googleEnabled)loadSocialScript('google-gsi','https://accounts.google.com/gsi/client',()=>{google.accounts.id.initialize({client_id:academyOAuthConfig.googleClientId,callback:async r=>{try{await completeAcademyOAuth('google',{idToken:r.credential});}catch(e){toast(e.message);}}});google.accounts.id.renderButton(document.querySelector('#academy-google-signin'),{theme:'outline',size:'large',width:360,text:'continue_with'});});const facebook=document.querySelector('[data-signin="facebook"]');if(academyOAuthConfig.facebookEnabled){facebook.hidden=false;window.fbAsyncInit=()=>FB.init({appId:academyOAuthConfig.facebookAppId,cookie:true,xfbml:false,version:'v26.0'});loadSocialScript('facebook-jssdk','https://connect.facebook.net/en_US/sdk.js');}}catch{/* Password sign-in remains available. */}}

function passwordRecoveryView(email = '') {
  return `<button type="button" class="close" data-action="close" aria-label="Close">×</button><h2>Reset your password</h2><p class="intro">Enter your registered ChessVerseAI email to request a six-digit reset code.</p><form id="academy-recovery"><label>Email<input type="email" name="email" value="${esc(email)}" required autocomplete="email"></label><div class="error" role="alert"></div><button type="submit" class="button">Send reset code</button></form>`;
}

document.addEventListener('click', event => {
  const control = event.target.closest?.('[data-signin]');
  if (!control) return;
  const dialog = $('#modal');
  if (control.dataset.signin === 'password') {
    const input = $('#academy-password'), show = input.type === 'password';
    input.type = show ? 'text' : 'password';
    control.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    control.setAttribute('aria-pressed', String(show));
    return;
  }
  if(control.dataset.signin==='facebook'){if(!window.FB){toast('Facebook sign-in is still loading. Please try again.');return;}FB.login(async response=>{if(!response.authResponse)return;try{await completeAcademyOAuth('facebook',{accessToken:response.authResponse.accessToken});}catch(e){toast(e.message);}},{scope:'public_profile,email'});return;}
  dialog.classList.remove('form-drawer');
  if (control.dataset.signin === 'forgot') dialog.innerHTML = passwordRecoveryView();
  else dialog.innerHTML = `<button type="button" class="close" data-action="close" aria-label="Close">×</button><h2>Bring your academy to ChessVerseAI</h2><p class="intro">Already part of an academy? Ask your administrator to add your verified ChessVerseAI email.</p><p class="small">For a new academy or school, contact EpitomeHub with your academy name and the email you use for ChessVerseAI.</p><a class="button" href="mailto:contactus@epitomehub.com?subject=ChessVerseAI%20Academy%20Access">Contact EpitomeHub ${icon('arrow')}</a>`;
  dialog.showModal();
});

document.addEventListener('submit', async event => {
  const form = event.target;
  if (form.id === 'login-form') {
    // Explicit opt-in remembers only the account identifier, never a password/token.
    try {
      if ($('#remember-identity')?.checked) localStorage.setItem('academy-remembered-identity', form.elements.identity.value);
      else localStorage.removeItem('academy-remembered-identity');
    } catch { /* Optional preference. */ }
    return;
  }
  if (!['academy-recovery','academy-reset'].includes(form.id)) return;
  event.preventDefault();
  const button = form.querySelector('[type=submit]'), error = form.querySelector('.error');
  button.disabled = true; error.textContent = '';
  try {
    const data = Object.fromEntries(new FormData(form));
    const response = await fetch('/api/auth/password/' + (form.id === 'academy-recovery' ? 'forgot' : 'reset'), {
      method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data)
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.message || 'Unable to reset your password. Please try again.');
    if (form.id === 'academy-recovery') {
      $('#modal').innerHTML = `<button type="button" class="close" data-action="close" aria-label="Close">×</button><h2>Check your email</h2><p class="intro">If this email is eligible, a reset code has been sent. Enter it below with your new password.</p><form id="academy-reset"><input type="hidden" name="email" value="${esc(data.email)}"><label>Six-digit code<input name="code" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" required autocomplete="one-time-code"></label><label>New password<input name="newPassword" type="password" minlength="8" maxlength="72" required autocomplete="new-password"></label><div class="error" role="alert"></div><button type="submit" class="button">Reset password</button></form>`;
    } else { $('#modal').close(); toast('Password reset. Sign in with your new password.'); }
  } catch (e) { error.textContent = e.message; }
  finally { button.disabled = false; }
});

if (!window.__ACADEMY_TEST__ && !state.data) login();
