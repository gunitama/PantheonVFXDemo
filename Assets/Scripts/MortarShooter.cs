using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MortarShooter : MonoBehaviour
{
    [Header("References")]
    private Transform firePoint;
    public GameObject projectilePrefab;
    public GameObject muzzleEffectPrefab;
    public GameObject impactEffectPrefab; 

    [Header("Settings")]
    public float shootForce = 20f;
    public float projectileLifeTime = 5f;

    private void Start()
    {
        firePoint = transform;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Shoot();
        }
    }

    void Shoot()
    {
        if (muzzleEffectPrefab)
            Instantiate(muzzleEffectPrefab, firePoint.position, firePoint.rotation);

        GameObject projectile = Instantiate(projectilePrefab, firePoint.position, firePoint.rotation);

        Rigidbody rb = projectile.GetComponent<Rigidbody>();
        if (rb)
            rb.velocity = firePoint.forward * shootForce;

        Projectile projScript = projectile.AddComponent<Projectile>();
        projScript.impactEffectPrefab = impactEffectPrefab;

        Destroy(projectile, projectileLifeTime);
    }
}
