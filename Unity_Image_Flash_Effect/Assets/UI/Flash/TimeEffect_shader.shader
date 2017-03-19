Shader "UICustom/ImageFlashEffect"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}

		_LightTex ("Light Texture", 2D) = "white" {}

		_LightColor("Light Color",Color) = (1,1,1,1)

		_LightPower("Light Power",Range(0,5)) = 1

		_LightScale("Light Scale" , Range(0.5,5)) = 1

		_LightAngle("Light Angle",Range(-180,180)) = 1

		//每次持续时间，受Angle和Scale影响
		_LightDuration("Light Duration",Range(0,10)) = 1
		//时间间隔，受Angle和Scale影响
		_LightInterval("Light Interval",Range(0,20)) = 3
		//非线性，受Angle和Scale影响
		_LightOffSetX("Light OffSet ",Range(-10,10)) = 0
	}

	SubShader
	{
		Tags 
		{
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Offset -1, -1
		Blend SrcAlpha OneMinusSrcAlpha 
        AlphaTest Greater 0.1

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 lightuv : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _LightTex ;
			float4  _LightTex_ST;

			half _LightInterval ;
			half _LightDuration ;

			half4 _LightColor ;
			half _LightPower ;

			half _LightAngle ;
			
			half _LightScale ;

			half _LightOffSetX ;
			half _LightOffSetY ;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				
                fixed currentTimePassed = fmod(_Time.y,_LightInterval);

				//uv offset, Sprite wrap mode need "Clamp"
				fixed offsetX = currentTimePassed / _LightDuration;
				fixed offsetY = currentTimePassed / _LightDuration;

				//fixed offsetX =  _LightDuration;
				//fixed offsetY =  _LightDuration;

                float angleInRad = 0.0174444 * _LightAngle;
				float sinInRad = sin(angleInRad);
				float cosInRad = cos(angleInRad);

				float2 offset ;
				offset.x = offsetX ;
				offset.y = offsetY ;

				float2 base = v.uv ;
				base.x -= _LightOffSetX ;
				base.y -= _LightOffSetX ;
				base = base / _LightScale ;

				float2 base2 = v.uv;
				base2.x  = base.x * cosInRad - base.y * sinInRad ;
				base2.y  = base.y * cosInRad + base.x * sinInRad ;

				o.lightuv = base2 + offset ;

				o.uv		 = TRANSFORM_TEX(v.uv, _MainTex);
				o.lightuv    = TRANSFORM_TEX(o.lightuv, _LightTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 mainCol   = tex2D(_MainTex, i.uv);
				fixed4 lightCol  = tex2D(_LightTex, i.lightuv);

				lightCol *= _LightColor ;

				//need blend
				//lightCol.rgb *= mainCol.rgb ;
				fixed4 fininalCol ;
				fininalCol.rgb   = mainCol.rgb +  lightCol.rgb * _LightPower;
				fininalCol.a =  mainCol.a * lightCol.a ;
				return fininalCol ;
			}
			ENDCG
		}
	}
}
