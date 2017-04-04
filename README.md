###Unity  Shader 效果（1） ：图片流光效果

@(Unity)

>很多游戏Logo中可以看到这种流光效果，一般的实现方案就是对带有光条的图片uv根据时间进行移动，然后和原图就行叠加实现，不过实现过程中稍稍有点需要注意的地方。之前考虑过[风宇冲](http://blog.sina.com.cn/s/blog_471132920101d8zf.html)的实现方式，但是考虑到shader中太多的计算，还是放弃了。
![mark](http://ohzzlljrf.bkt.clouddn.com/blog/20170319/165737095.png)
#### 基础版本
```
Shader "UICustom/ImageFlashEffect2"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}

		_LightTex ("Light Texture", 2D) = "white" {}

		_LightColor("Light Color",Color) = (1,1,1,1)

		_LightPower("Light Power",Range(0,5)) = 1

		//每次持续时间，受Angle和Scale影响
		_LightDuration("Light Duration",Range(0,10)) = 1
		//时间间隔，受Angle和Scale影响
		_LightInterval("Light Interval",Range(0,20)) = 3
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

			half _LightOffSetX ;
			half _LightOffSetY ;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                fixed currentTimePassed = fmod(_Time.y,_LightInterval);
				//uv offset, Sprite wrap mode need "Clamp"
				fixed offsetX = currentTimePassed / _LightDuration;
				fixed offsetY = currentTimePassed / _LightDuration；
				fixed2 offset ;
				offset.x = offsetX - 0.5f;
				offset.y = offsetY - 0.5f;

				o.lightuv = v.uv  + offset ;

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
```
需要注意的点：
1. 时间间隔问题
```
fixed currentTimePassed = fmod(_Time.y,_LightInterval);
//uv offset, Sprite wrap mode need "Clamp"
fixed offsetX = currentTimePassed / _LightDuration;
fixed offsetY = currentTimePassed / _LightDuration；
```
> offsetX 、offsetY其实是0~_LightInterval的数值，需要设置图片为光线图片的Wrap模式为Clamp，才能实现时间间隔控制
2. 色彩融合
Pixel着色器中frag()函数是通过原始颜色和光线颜色叠加的方式实现的，也有将光线颜色和原图混合后再叠加的做法，这个我觉得看实际应用。注意alpha的控制

#### 优化
##### 1. 增加角度和大小控制
基本版本的实现中光线只能根据流光图片中亮线的宽度和方向决定实际的滚动方向和大小。有时候如果需要经常调节方向和大小，可以考虑加入相关因素。流光的Uv是通过原图当前Uv加上时间轴参数获得，可以考虑通过修改流光uv的计算方式来实现。如下面代码。不过这种方式增加了一定计算量，不需要的话则直接跳过。还有一点就是流光贴图必须是垂直或者水平，不然
```
float2 base = v.uv ;
base.x -= _LightOffSetX ;
base.y -= _LightOffSetX ;
base = base / _LightScale ;

float2 base2 = v.uv;
base2.x  = base.x * cosInRad - base.y * sinInRad ;
base2.y  = base.y * cosInRad + base.x * sinInRad ;

o.lightuv = base2 + offset ;
```
##### 材质复用
只是想不同的图片都是使用相同的材质，应该保证每个图片的效果都可以独立进行修改保存，可以考虑每张图片都创建一份材质，然后修改其参数。
```
   void UpdateParam()
   {
       if (Material == null)
       {
           Debug.LogWarning("Metarial is miss");
           return;
       }

       if (mGraphic == null)
       {
           mGraphic = GetComponent<MaskableGraphic>();
       }

       if (mGraphic is Text)
       {
           Debug.LogError("FlashEffec need component type of Image、RawImage");
           return;
       }

       if (mDynaMaterial == null)
       {
           mDynaMaterial = new Material(Material);
           mDynaMaterial.name = mDynaMaterial.name + "(Copy)";
           mDynaMaterial.hideFlags = HideFlags.DontSave | HideFlags.NotEditable;
       }

       if (mDynaMaterial == null)
       {
           return;
       }

       mDynaMaterial.mainTexture = null;
       if (OverrideTexture != null)
       {
           mDynaMaterial.mainTexture = OverrideTexture;

           if (mGraphic is RawImage)
           {
               RawImage img = mGraphic as RawImage;
               img.texture = null;
           }
           else if (mGraphic is Image)
           {
               Image img = mGraphic as Image;
               img.sprite = null;
           }
       }
       else
       {
           mDynaMaterial.mainTexture = mGraphic.mainTexture;
       }

       if (Duration > Interval)
       {
           Debug.LogWarning("ImageFlashEffect.UpdateParam:Duration need less Interval");
           Interval = Duration + 0.5f;
       }

       mDynaMaterial.SetColor("_LightColor", Color);
       mDynaMaterial.SetFloat("_LightPower", Power);
       mDynaMaterial.SetFloat("_LightScale", Scale);
       mDynaMaterial.SetFloat("_LightAngle", Angle);
       mDynaMaterial.SetFloat("_LightDuration", Duration);
       mDynaMaterial.SetFloat("_LightInterval", Interval);
       mDynaMaterial.SetFloat("_LightOffSetX", OffSet);
       mGraphic.material = mDynaMaterial;
       mGraphic.SetMaterialDirty();
   }
```

#### 参考
http://blog.csdn.net/qq992817263/article/details/51200424
http://qkxue.net/info/169189/Unity-Simple-Shaderlab-uGui-shader-1


