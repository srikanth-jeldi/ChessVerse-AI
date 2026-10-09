'use strict';
let pricingRequest=0;
async function renderPublicPlans(){
 const request=++pricingRequest,container=document.querySelector('#public-plans'),status=document.querySelector('#pricing-status');
 container.replaceChildren();status.textContent='Loading current plans…';
 try{const response=await fetch('/api/v1/academy/onboarding/plans?country='+encodeURIComponent(document.querySelector('#pricing-country').value));if(!response.ok)throw Error('Plans could not be loaded. Please try again or contact support.');const catalog=await response.json();if(request!==pricingRequest)return;
 status.textContent=catalog.checkoutAvailable?'Start your 7-day free trial. Choose a paid plan when you are ready.':'Registration and the demo are open. Online checkout for this billing location is not yet available.';
 const cycle=document.querySelector('#pricing-cycle'),annual=cycle.querySelector('option[value="YEARLY"]');
 annual.disabled=!catalog.plans.some(p=>p.enabled&&p.annual_amount_minor);
 if(annual.disabled)cycle.value='MONTHLY';
 const yearly=cycle.value==='YEARLY';
 for(const plan of catalog.plans.filter(p=>p.enabled&&(!yearly||p.annual_amount_minor))){const card=document.createElement('section');card.className='plan';const title=document.createElement('h2');title.textContent=plan.name;const price=document.createElement('p');price.className='price';price.textContent=new Intl.NumberFormat(undefined,{style:'currency',currency:plan.currency}).format((yearly?plan.annual_amount_minor:plan.amount_minor)/100);const period=document.createElement('small');period.textContent=' '+plan.currency+(yearly?' / year':' / month');price.append(period);const seats=document.createElement('p');seats.textContent=plan.seats+' students · '+({STARTER:1,GROWTH:5,SCHOOL:15}[plan.plan_code])+' coach'+(plan.plan_code==='STARTER'?'':'es')+' · excluding applicable taxes';const link=document.createElement('a');link.href='/academy';link.className='primary';link.textContent='Start free trial →';card.append(title,price,seats,link);container.append(card);}
 if(!container.children.length)status.textContent='This billing period is not yet available for your location. Choose monthly billing or contact us for pricing.';
 }catch(error){if(request===pricingRequest)status.textContent=error.message;}
}
document.querySelector('#pricing-country').addEventListener('change',renderPublicPlans);
document.querySelector('#pricing-cycle').addEventListener('change',renderPublicPlans);
renderPublicPlans();
