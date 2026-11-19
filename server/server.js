const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// CORS 설정
app.use(cors({
  origin: ['http://localhost:3000', 'https://your-app-domain.com'], // 실제 앱 도메인으로 변경
  credentials: true
}));

app.use(express.json());

// Firebase Admin 초기화
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL
});

// 카카오 토큰 검증 및 Firebase Custom Token 발급
app.post('/auth/kakao', async (req, res) => {
  try {
    const { accessToken } = req.body;
    
    if (!accessToken) {
      return res.status(400).json({ error: 'Access token is required' });
    }

    // 카카오 API로 사용자 정보 조회
    const kakaoUserInfo = await getKakaoUserInfo(accessToken);
    
    if (!kakaoUserInfo) {
      return res.status(401).json({ error: 'Invalid Kakao access token' });
    }

    // Firebase Custom Token 생성
    const customToken = await admin.auth().createCustomToken(kakaoUserInfo.id.toString(), {
      provider: 'kakao',
      kakaoId: kakaoUserInfo.id.toString(),
      email: kakaoUserInfo.kakao_account?.email,
      displayName: kakaoUserInfo.kakao_account?.profile?.nickname,
      photoURL: kakaoUserInfo.kakao_account?.profile?.profile_image_url
    });

    res.json({
      customToken,
      userInfo: {
        id: kakaoUserInfo.id,
        email: kakaoUserInfo.kakao_account?.email,
        displayName: kakaoUserInfo.kakao_account?.profile?.nickname,
        photoURL: kakaoUserInfo.kakao_account?.profile?.profile_image_url
      }
    });

  } catch (error) {
    console.error('Kakao auth error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 카카오 사용자 정보 조회
async function getKakaoUserInfo(accessToken) {
  try {
    const response = await axios.get('https://kapi.kakao.com/v2/user/me', {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8'
      }
    });
    
    return response.data;
  } catch (error) {
    console.error('Kakao API error:', error.response?.data || error.message);
    return null;
  }
}

// 헬스 체크
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 