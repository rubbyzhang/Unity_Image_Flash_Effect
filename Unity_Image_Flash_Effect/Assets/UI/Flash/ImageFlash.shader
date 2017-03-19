Shader "UICustom/ImageFlash"
{
    Properties 
	{
        _MainTex ("Texture", 2D) = "white" { }
		//闪光颜色
        _FlashColor("Color(RGB)",Color) = (1,1,1,1)

		//闪光宽度
		_FlashWidth("Width" , Range(0.1, 0.5)) = 0.2 

        //闪光角度
        _Angle("Angle",Range(0,180)) = 45

        //闪光持续时间
        _FlashDuration("Duration",Range(0,5)) = 1

		//闪光间隔
     	_Interval("Interval",Range(0,10)) = 1
    }

    SubShader
    {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		Blend SrcAlpha OneMinusSrcAlpha 
        AlphaTest Greater 0.1

        pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
       
            sampler2D _MainTex;
            float4 _MainTex_ST;
			half _Angle ;
			half _FlashDuration ;
			half _Interval ;
  			fixed4 _FlashColor ;
		  	half _FlashWidth ;	
			         
            struct v2f 
			{
                float4  pos : SV_POSITION;
                float2  uv : TEXCOORD0;
            };
           
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos =    mul(UNITY_MATRIX_MVP,v.vertex);
                o.uv  =    TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            //闪光效果
            // angle 发光交付
            float GetFlashValue(float2 uv,float angle,float xLength, float duration , int interval)
            {
                //亮度值
                half brightness =0;
                //倾斜角
                float angleInRad = 0.0174444 * angle;
                //当前时间
                float currentTime = _Time.y;
                //获取本次光照的起始时间
                int currentTimeInt = _Time.y / interval;
                currentTimeInt *= interval;
                float currentTimePassed = currentTime -currentTimeInt;
                //底部左边界和右边界
                half xBottomLeftBound;
                half xBottomRightBound;

                //此点边界
                half xPointLeftBound;
                half xPointRightBound;
                half x0 = currentTimePassed / duration;
       
                //设置右边界
                xBottomRightBound = x0;
                //设置左边界
                xBottomLeftBound  = x0 - xLength;
				
                //投影至x的长度 = y/ tan(angle)
                half xProjL;
                xProjL= (uv.y)/tan(angleInRad);

                //此点的左边界 = 底部左边界 - 投影至x的长度
                xPointLeftBound = xBottomLeftBound - xProjL;
                //此点的右边界 = 底部右边界 - 投影至x的长度
                xPointRightBound = xBottomRightBound - xProjL;
               
                //边界加上一个偏移
                xPointLeftBound += 0.2f;
                xPointRightBound += 0.2f;
               
                //如果该点在区域内
                if(uv.x > xPointLeftBound && uv.x < xPointRightBound)
                {
                    //得到发光区域的中心点
                    half midness = (xPointLeftBound + xPointRightBound)/2;
                   
                    //趋近中心点的程度，0表示位于边缘，1表示位于中心点
                    half rate= (xLength -2*abs(uv.x - midness))/ (xLength);
                    brightness = rate;
                }

                return max(brightness,0);
            }

            float4 frag (v2f i) : COLOR
            {
                 float4 outp;
                
                 //根据uv取得纹理颜色，和常规一样
                float4 texCol = tex2D(_MainTex,i.uv);
       
                //传进i.uv等参数，得到亮度值
                float tmpBrightness = GetFlashValue(i.uv, _Angle,_FlashWidth,_FlashDuration,_Interval);
           
                //图像区域，判定设置为 颜色的A > 0.5,输出为材质颜色+光亮值
                if(texCol.w > 0.5)
				{
					outp  = texCol + _FlashColor * tmpBrightness;
				}
                else
				{
                    outp = float4(0,0,0,0);
				}
                return outp;
            }

            ENDCG
        }
    }
}