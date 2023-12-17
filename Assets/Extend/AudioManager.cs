using System;
using System.Collections;
using System.Collections.Generic;
using Extend.Network.HttpClient;
using UnityEngine;
using XLua;

namespace Extend
{
	[LuaCallCSharp]
	public class AudioManager : MonoBehaviour
	{
		public static AudioManager Instance
		{
			get
			{
				if (_instance == null)
				{
					var go = new GameObject("AudioManager");
					DontDestroyOnLoad(go);
					_instance = go.AddComponent<AudioManager>();
				}

				return _instance;
			}
			private set { _instance = value; }
		}

		private static AudioManager _instance;

		private static Dictionary<AudioSourceType, AudioSource> _dic = new Dictionary<AudioSourceType, AudioSource>();

		private AudioSource GetAudio(AudioSourceType audioSourceType)
		{
			if (_dic.ContainsKey(audioSourceType))
			{
				return _dic[audioSourceType];
			}
			else
			{
				var audioSource = gameObject.AddComponent<AudioSource>();
				audioSource.playOnAwake = false;
				_dic.Add(audioSourceType, audioSource);
				return audioSource;
			}
		}

		public AudioSource AddAudioObj(AudioSourceType type, GameObject target)
		{
			if (!_dic.ContainsKey(type))
			{
				var audioSource = target.GetComponent<AudioSource>();
				audioSource.playOnAwake = false;
				_dic.Add(type, audioSource);
				Debug.Log("--AddAudioObj");
				return audioSource;
			}
			else
			{
				return _dic[type];
			}
		}

		public void RemoveAudioObj(AudioSourceType type)
		{
			if (_dic.ContainsKey(type))
			{
				_dic.Remove(type);
			}
		}

		public AudioSource Play(AudioSourceType audioSourceType, AudioClip clip)
		{
			var audioSource = GetAudio(audioSourceType);
			if (audioSource != null)
			{
				audioSource.clip = clip;
				if (clip != null)
				{
					CheckConflict(audioSourceType);
					audioSource.Play();
					audioSource.volume = 1;
				}
			}
			
			return audioSource;
		}

		public void Pause(AudioSourceType audioSourceType)
		{
			var audioSource = GetAudio(audioSourceType);
		}

		public bool IsPlaying(AudioSourceType audioSourceType)
		{
			var audioSource = GetAudio(audioSourceType);
			return audioSource.isPlaying;
		}

		public void Resume(AudioSourceType audioSourceType)
		{
			var audioSource = GetAudio(audioSourceType);
			if (audioSource.clip != null)
				audioSource.UnPause();
		}

		public void Stop(AudioSourceType audioSourceType)
		{
			var audioSource = GetAudio(audioSourceType);
			audioSource.Stop();
			audioSource.clip = null;
		}

		public void Mute(AudioSourceType audioSourceType, bool value)
		{
			var audioSource = GetAudio(audioSourceType);
			audioSource.volume = value ? 0 : 1;
		}

		public void ReleaseClip(AudioSourceType audioSourceType)
		{
			var audioSource = GetAudio(audioSourceType);
			audioSource.clip = null;
		}

		private void CheckConflict(AudioSourceType audioSourceType)
		{
			if (audioSourceType == AudioSourceType.Speak)
			{
				var ip = GetAudio(AudioSourceType.IP);
				if (ip.isPlaying)
				{
					ip.Stop();
				}
			}
			else if (audioSourceType == AudioSourceType.IP)
			{
				var speak = GetAudio(AudioSourceType.Speak);
				if (speak.isPlaying)
				{
					speak.Stop();
				}
			}
		}

		public void PlayRemoteAudio(string url)
		{
			Debug.LogWarning($"PlayRemoteAudio {url}");
			HttpFileRequest req = new HttpFileRequest();
			try
			{
				req.RequestAudio(url,GetAudioType(url), clip =>
				{
					if (clip!=null)
					{
						Play(AudioSourceType.Speak, clip);
					}
				});
			}
			catch (Exception e)
			{
				Debug.LogError($"PlayRemoteAudio error {e}");
			}
		}

		public void DownLoadFile(string uri, Action<string> callback)
		{
			HttpFileRequest req = new HttpFileRequest();
			req.RequestFile(uri,callback);
		}
		public  AudioType GetAudioType(string url)
		{
			var ret = AudioType.MPEG;

			if (url.EndsWith(".wav") || url.EndsWith("wav?")|| url.EndsWith("/FTwav")) {
				ret = AudioType.WAV;
			}
			else if (url.EndsWith(".mp3") || url.EndsWith("mp3?") || url.EndsWith("/FTmp3")) {
				ret = AudioType.MPEG;
			}
			else if (url.EndsWith(".ogg") || url.EndsWith("ogg?") || url.EndsWith("/FTorg")) {
				ret = AudioType.OGGVORBIS;
			}

			return ret;
		}
	}

	public enum AudioSourceType
	{
		Speak,
		IP,
		Env,
		BGM
	}
}