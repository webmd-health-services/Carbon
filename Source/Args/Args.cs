
using System;

public static class Args
{
	public static void Main(string[] args)
	{
		foreach (var arg in args)
		{
			Console.WriteLine(arg);
		}
	}
}