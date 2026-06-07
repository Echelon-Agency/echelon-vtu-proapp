import { NextResponse } from 'next/server';
import axios from 'axios';

export async function POST(request: Request) {
  try {
    const { phone, plan_id, network_id } = await request.json();

    // Call ClubKonnect API
    const response = await axios.get('https://www.clubkonnect.com/APIParaGetDataBundleV1.asp', {
      params: {
        UserID: process.env.CLUBKONNECT_USERID,
        APIKey: process.env.CLUBKONNECT_API_KEY,
        MobileNetwork: network_id,
        DataPlan: plan_id,
        MobileNumber: phone,
      },
    });

    return NextResponse.json(response.data);
  } catch (error) {
    return NextResponse.json({ error: 'Purchase failed' }, { status: 500 });
  }
}
