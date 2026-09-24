import 'finance_engine.dart';
import 'models.dart';

class LocalAdvisor {
  static String answer(
    String question,
    FinanceProfile profile,
    FinancialGoal goal,
    String language,
  ) {
    final a = FinanceEngine.assess(profile, goal);
    final q = question.toLowerCase();
    final hindi = language.startsWith('hi');
    if (RegExp(r'claim|hospital|दावा').hasMatch(q)) {
      return hindi
          ? 'बीमा दावे के लिए Insurance claims खोलें। पॉलिसी नंबर, अस्पताल, इलाज की तारीख और बिल की राशि भरें। बिल, डिस्चार्ज सारांश और पॉलिसी की जाँच करें। यह स्थानीय ड्राफ्ट है; बीमाकर्ता को नहीं भेजा जाता।'
          : 'Open Insurance claims to prepare a draft. Gather your policy schedule, itemised hospital bills, discharge summary and any documents requested by your insurer. Check waiting periods, exclusions, co-pay and pre-authorisation requirements in your policy. FINPATH can help organise the claim, but the insurer decides coverage and settlement.';
    }
    if (RegExp(r'insur|cover|बीमा').hasMatch(q)) {
      return hindi
          ? 'आपका स्वास्थ्य बीमा कवर ₹${profile.healthCover.round()} है। Insurance claims में कवरेज का अनुमान देखें और अपनी पॉलिसी की शर्तें जाँचें।'
          : 'Your entered health cover is INR ${profile.healthCover.round()}; life cover is INR ${profile.lifeCover.round()}. The insurance page compares this with clearly labelled demo planning assumptions. Actual needs depend on your family, location, employer benefits and policy conditions.';
    }
    if (RegExp(r'doc|upload|paper|दस्तावेज').hasMatch(q)) {
      return hindi
          ? 'Documents में नमूना वेतन पर्ची या अपनी फाइल जोड़ें। निकाले गए विवरण की समीक्षा करें। पुष्टि के बाद जानकारी आपकी प्रोफाइल और आवेदन में भरी जाएगी।'
          : 'Open Documents and try the sample payslip, paste labelled text, or choose a file. TXT and labelled CSV work locally. PDF/images need Gemini and AI consent. Review the extracted values before autofilling your profile. Extraction does not verify identity.';
    }
    if (RegExp(r'interest|repay|tenure|ब्याज').hasMatch(q)) {
      return hindi
          ? 'इस योजना में अनुमानित मासिक किस्त ₹${a.emi.round()}, कुल ब्याज ₹${a.interest.round()} और कुल ऋण भुगतान ₹${a.repayment.round()} है। अवधि ${goal.months} महीने है। फीस शामिल नहीं है।'
          : 'For INR ${(goal.amount - goal.downPayment).round()} borrowed at ${goal.rate}% a year over ${goal.months} months, your estimated EMI is INR ${a.emi.round()}. Total interest is INR ${a.interest.round()}, and loan repayment is INR ${a.repayment.round()}. The down payment is separate. A longer tenure lowers EMI but usually increases total interest. Fees are not included.';
    }
    if (RegExp(r'emi|afford|budget|safe|plan|किस्त|खर्च').hasMatch(q)) {
      return hindi
          ? 'आपकी अनुमानित मासिक किस्त ₹${a.emi.round()} है। खर्च और सभी किस्तों के बाद हर महीने ₹${a.remaining.round()} बचेंगे। बचत लगभग ${a.bufferMonths.toStringAsFixed(1)} महीने के खर्च के बराबर है। ${a.affordable ? 'योजना डेमो बजट नियमों में फिट है।' : 'योजना की समीक्षा करें; बचत या बजट पर दबाव पड़ सकता है।'}'
          : 'Your estimated EMI is INR ${a.emi.round()}/month. After living expenses and all EMIs, INR ${a.remaining.round()} remains each month. After your down payment, savings cover ${a.bufferMonths.toStringAsFixed(1)} months of total outgo. ${a.affordable ? 'This fits our demo rules: all EMIs under 35% of income, 20% income reserved and 3 months of savings buffer.' : a.reasons.join(' ')} Try the simulator to see how a smaller loan, longer tenure or income drop changes the picture.';
    }
    if (RegExp(r'approval|eligible|status|loan.*when').hasMatch(q)) {
      return 'The rule-based fit is “${FinanceEngine.eligibility(profile, goal)}”, based on your self-reported credit score and budget. No lender is connected and this is not an approval prediction. Your journey page tracks a local demo application; only a real lender can approve and disburse a loan.';
    }
    return hindi
        ? 'मैं EMI, बजट, दस्तावेज और बीमा दावे में मदद कर सकता हूँ। अपना सवाल लिखें या बोलें। खुले सवालों के लिए Gemini चालू करें; स्थानीय गणना बिना API कुंजी भी काम करती है।'
        : 'I can explain your EMI and budget, help with documents, or guide an insurance claim. Try “Can I afford this EMI?” or “What do I need for a health claim?” This is the local, rule-based guide. Enable Gemini in Privacy for open-ended conversations and additional languages.';
  }
}
