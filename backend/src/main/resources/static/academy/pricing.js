'use strict';
let pricingRequest=0;
async function renderPublicPlans(){
 const request=++pricingRequest,container=document.querySelector('#public-plans'),status=document.querySelector('#pricing-status');
 container.replaceChildren();status.textContent='Loading current plans…';
 try{const response=await fetch('/api/v1/academy/onboarding/plans?country='+encodeURIComponent(document.querySelector('#pricing-country').value));if(!response.ok)throw Error('Plans could not be loaded. Please try again or contact support.');const catalog=await response.json();if(request!==pricingRequest)return;
 status.textContent=catalog.checkoutAvailable?'Register your academy to choose a plan and review the final total.':'Registration and the demo are open. Online checkout for this billing location is not yet available.';
 for(const plan of catalog.plans.filter(p=>p.enabled)){const card=document.createElement('section');card.className='plan';const title=document.createElement('h2');title.textContent=plan.name;const price=document.createElement('p');price.className='price';price.textContent=new Intl.NumberFormat('en',{style:'currency',currency:plan.currency,maximumFractionDigits:0}).format(plan.amount_minor/100);const period=document.createElement('small');period.textContent=' / month';price.append(period);const seats=document.createElement('p');seats.textContent=plan.seats+' student seats · excluding applicable taxes';const link=document.createElement('a');link.href='/academy';link.className='primary';link.textContent='Register your academy →';card.append(title,price,seats,link);container.append(card);}
 if(!container.children.length)status.textContent='No plans are currently listed. Contact us for pricing.';
 }catch(error){if(request===pricingRequest)status.textContent=error.message;}
}
document.querySelector('#pricing-country').addEventListener('change',renderPublicPlans);
renderPublicPlans();
